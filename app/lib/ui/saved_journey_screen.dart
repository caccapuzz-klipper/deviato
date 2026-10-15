import 'dart:async';

import 'package:flutter/material.dart';

import '../core/models/saved_journey.dart';
import '../core/models/transit.dart';
import '../core/sources/trip_updates_gtt.dart';
import '../data/app_repository.dart';
import 'journey_editor_screen.dart';
import 'line_badge.dart';
import 'theme.dart';

/// Schermata interattiva di una pagina di salvataggio percorsi con cambi multipli.
///
/// Mostra gli arrivi in tempo reale per ogni cambio, ordina i mezzi secondo
/// la priorità trascinabile dell'utente, e calcola/evidenzia automaticamente
/// la coincidenza per qualche secondo al tocco di un orario.
class SavedJourneyScreen extends StatefulWidget {
  const SavedJourneyScreen({
    required this.journey,
    required this.repo,
    super.key,
  });

  final SavedJourneyPage journey;
  final AppRepository repo;

  @override
  State<SavedJourneyScreen> createState() => _SavedJourneyScreenState();
}

class _SavedJourneyScreenState extends State<SavedJourneyScreen> {
  late SavedJourneyPage _journey;
  final _source = TripUpdatesGttSource();

  // Arrivi memorizzati per ogni tappa (stepId -> List<_ArrivalItem>)
  final Map<String, List<_ArrivalItem>> _stepArrivals = {};
  final Map<String, bool> _stepLoading = {};
  final Map<String, String?> _stepErrors = {};

  DateTime _oraRif = DateTime.now();
  Timer? _timerAutoRefresh;

  // Stato per l'evidenziazione temporanea delle coincidenze
  Timer? _highlightTimer;
  _CoincidenzaCalcolata? _coincidenzaAttiva;
  final Set<String> _highlightedKeys = {};

  @override
  void initState() {
    super.initState();
    _journey = widget.journey;
    _caricaTutto();
    // Auto-refresh ogni 30 secondi
    _timerAutoRefresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _oraRif = DateTime.now());
        _caricaTutto(silenzioso: true);
      }
    });
  }

  @override
  void dispose() {
    _timerAutoRefresh?.cancel();
    _highlightTimer?.cancel();
    super.dispose();
  }

  Future<void> _caricaTutto({bool silenzioso = false}) async {
    if (!silenzioso) {
      setState(() {
        for (final s in _journey.steps) {
          _stepLoading[s.id] = true;
          _stepErrors[s.id] = null;
        }
      });
    }

    final futures = <Future<void>>[];
    for (final s in _journey.steps) {
      futures.add(_caricaStep(s));
    }
    await Future.wait(futures);

    if (mounted) {
      setState(() {
        _oraRif = DateTime.now();
      });
    }
  }

  Future<void> _caricaStep(SavedCambioStep step) async {
    final tuttiArrivi = <_ArrivalItem>[];
    String? errore;

    for (final stopId in step.stopIds) {
      final code = step.codeFor(stopId);
      final stopName = step.nameFor(stopId);
      final isPreferenziale = step.preferenzialeStopId == stopId;

      try {
        final res = await _source.fetchArriviPalina(code, stopId: stopId);
        for (final linea in res.linee) {
          final nomeLineaPulito = linea.linea.replaceAll('U', '').trim();
          final nomeLineaOriginale = linea.linea.trim();

          // Filtra solo le linee selezionate dall'utente per questo cambio
          final inclusa = step.lineNames.any((ln) =>
              ln.toUpperCase() == nomeLineaPulito.toUpperCase() ||
              ln.toUpperCase() == nomeLineaOriginale.toUpperCase());

          if (!inclusa && step.lineNames.isNotEmpty) continue;

          for (final pass in linea.passaggi) {
            tuttiArrivi.add(_ArrivalItem(
              key: '${step.id}_${stopId}_${linea.linea}_${pass.orario}',
              stepId: step.id,
              stopId: stopId,
              stopCode: code,
              stopName: stopName,
              isPreferenziale: isPreferenziale,
              linea: linea.linea,
              lineaShort: nomeLineaPulito,
              direzione: linea.direzione.isNotEmpty ? linea.direzione : (linea.direzioneBreve ?? ''),
              passaggio: pass,
              hasAvviso: linea.avviso,
            ));
          }
        }
      } catch (e) {
        errore = 'Impossibile scaricare orari per alcune fermate';
      }
    }

    // Ordinamento:
    // 1. Fermate preferenziali
    // 2. Priorità trascinabile delle linee definita dall'utente
    // 3. Orario di arrivo crescente
    final priorita = step.priorityOrder;
    tuttiArrivi.sort((a, b) {
      // 1. Se una è preferenziale e l'altra no
      if (a.isPreferenziale != b.isPreferenziale) {
        return a.isPreferenziale ? -1 : 1;
      }

      // 2. Priorità linea personalizzata
      final indexA = priorita.indexWhere((p) => p.toUpperCase() == a.lineaShort.toUpperCase());
      final indexB = priorita.indexWhere((p) => p.toUpperCase() == b.lineaShort.toUpperCase());
      if (indexA != -1 && indexB != -1 && indexA != indexB) {
        return indexA.compareTo(indexB);
      }
      if (indexA != -1 && indexB == -1) return -1;
      if (indexA == -1 && indexB != -1) return 1;

      // 3. Orario cronologico
      return a.passaggio.orario.compareTo(b.passaggio.orario);
    });

    if (mounted) {
      setState(() {
        _stepArrivals[step.id] = tuttiArrivi;
        _stepLoading[step.id] = false;
        _stepErrors[step.id] = errore;
      });
    }
  }

  /// Calcola la coincidenza per le tappe successive al tocco di un orario
  void _selezionaOrarioETracciaCoincidenze(_ArrivalItem arrivo, int currentStepIndex) {
    if (currentStepIndex >= _journey.steps.length - 1) {
      // Ultimo cambio: non ci sono cambi successivi da calcolare
      return;
    }

    _highlightTimer?.cancel();
    _highlightedKeys.clear();

    final stepPartenza = _journey.steps[currentStepIndex];
    final orarioPartenza = arrivo.passaggio.orario;
    final parti = orarioPartenza.split(':');
    if (parti.length < 2) return;
    final h = int.tryParse(parti[0]) ?? _oraRif.hour;
    final m = int.tryParse(parti[1]) ?? _oraRif.minute;

    var oraCorrente = DateTime(_oraRif.year, _oraRif.month, _oraRif.day, h, m);
    if (oraCorrente.isBefore(_oraRif.subtract(const Duration(hours: 2)))) {
      oraCorrente = oraCorrente.add(const Duration(days: 1));
    }

    final dettagli = <String>[];
    dettagli.add('Partenza (${stepPartenza.title}): ${arrivo.lineaShort} alle $orarioPartenza da ${arrivo.stopName}');

    // Calcola per ciascuna tappa successiva
    for (var i = currentStepIndex; i < _journey.steps.length - 1; i++) {
      final stepUscente = _journey.steps[i];
      final stepEntrante = _journey.steps[i + 1];

      // Tempo stimato di percorrenza tratta + tempo a piedi / trasferimento
      const tempoCorsaMedioMinuti = 12;
      final tempoCammino = stepUscente.transferMinutes;
      final tempoTotaleTratta = Duration(minutes: tempoCorsaMedioMinuti + tempoCammino);

      final oraPronto = oraCorrente.add(tempoTotaleTratta);
      final oraMinimaStr = '${oraPronto.hour.toString().padLeft(2, '0')}:${oraPronto.minute.toString().padLeft(2, '0')}';

      // Cerca tra gli arrivi dello step successivo il primo >= oraMinimaStr
      final arriviSuccessivi = _stepArrivals[stepEntrante.id] ?? const [];
      _ArrivalItem? coincidenzaTrovata;

      for (final a in arriviSuccessivi) {
        if (a.passaggio.orario.compareTo(oraMinimaStr) >= 0) {
          coincidenzaTrovata = a;
          break;
        }
      }

      if (coincidenzaTrovata != null) {
        _highlightedKeys.add(coincidenzaTrovata.key);
        final minAttesa = coincidenzaTrovata.passaggio.minutiMancanti(oraPronto) ?? 0;
        dettagli.add(
          '➔ ${stepEntrante.title}: Linea ${coincidenzaTrovata.lineaShort} alle ${coincidenzaTrovata.passaggio.orario} (attesa ~${minAttesa.clamp(0, 60)} min)',
        );
        // Avanza oraCorrente per la tappa ancora dopo (se esiste)
        final pArr = coincidenzaTrovata.passaggio.orario.split(':');
        final hArr = int.tryParse(pArr[0]) ?? oraPronto.hour;
        final mArr = int.tryParse(pArr[1]) ?? oraPronto.minute;
        oraCorrente = DateTime(oraPronto.year, oraPronto.month, oraPronto.day, hArr, mArr);
      } else {
        dettagli.add(
          '➔ ${stepEntrante.title}: nessun passaggio trovato dopo le $oraMinimaStr',
        );
      }
    }

    setState(() {
      _coincidenzaAttiva = _CoincidenzaCalcolata(
        orarioPartenza: orarioPartenza,
        lineaPartenza: arrivo.lineaShort,
        dettagli: dettagli,
      );
    });

    // Mette in highlight per qualche secondo (6s) e poi si resetta automaticamente
    _highlightTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _highlightedKeys.clear();
          _coincidenzaAttiva = null;
        });
      }
    });
  }

  void _apriModifica() async {
    final aggiornata = await Navigator.push<SavedJourneyPage>(
      context,
      MaterialPageRoute(
        builder: (_) => JourneyEditorScreen(
          repo: widget.repo,
          initialJourney: _journey,
        ),
      ),
    );

    if (aggiornata != null && mounted) {
      setState(() {
        _journey = aggiornata;
      });
      _caricaTutto();
    }
  }

  void _apriDialogPriorita(SavedCambioStep step) {
    final items = List<String>.from(step.priorityOrder.isNotEmpty ? step.priorityOrder : step.lineNames);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.drag_indicator),
                    const SizedBox(width: 8),
                    Text(
                      'Priorità per ${step.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Trascina le linee per cambiare l\'ordine in cui compaiono gli arrivi.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ReorderableListView(
                    shrinkWrap: true,
                    onReorder: (oldIndex, newIndex) {
                      setModalState(() {
                        if (oldIndex < newIndex) newIndex -= 1;
                        final item = items.removeAt(oldIndex);
                        items.insert(newIndex, item);
                      });
                      final newStep = step.copyWith(priorityOrder: List<String>.from(items));
                      final stepIdx = _journey.steps.indexWhere((s) => s.id == step.id);
                      if (stepIdx != -1) {
                        final updatedSteps = List<SavedCambioStep>.from(_journey.steps);
                        updatedSteps[stepIdx] = newStep;
                        final updatedJourney = _journey.copyWith(steps: updatedSteps);
                        widget.repo.saveJourney(updatedJourney);
                        setState(() {
                          _journey = updatedJourney;
                        });
                        _caricaStep(newStep);
                      }
                    },
                    children: [
                      for (final l in items)
                        ListTile(
                          key: ValueKey(l),
                          leading: const Icon(Icons.reorder),
                          title: Text(
                            'Linea $l',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Chip(label: Text(l)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Fatto'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColors = StatusColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _journey.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_journey.cambiCount} ${_journey.cambiCount == 1 ? "cambio" : "cambi"} · ${_journey.steps.length} tratte',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica percorso',
            onPressed: _apriModifica,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna orari',
            onPressed: () => _caricaTutto(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _caricaTutto(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Banner di coincidenza calcolata (se attivo)
            if (_coincidenzaAttiva != null) ...[
              _buildCoincidenzaBanner(theme, scheme),
              const SizedBox(height: 14),
            ],

            // Indicatore tempo di riferimento
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Orari aggiornati alle ${_oraRif.hour.toString().padLeft(2, '0')}:${_oraRif.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    'Tocca un orario per calcolare la coincidenza',
                    style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Visualizzazione delle tappe
            for (var i = 0; i < _journey.steps.length; i++) ...[
              _buildStepSection(i, theme, scheme, statusColors),
              if (i < _journey.steps.length - 1)
                _buildTransferIndicator(i, theme, scheme),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCoincidenzaBanner(ThemeData theme, ColorScheme scheme) {
    final coinc = _coincidenzaAttiva!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.16),
        border: Border.all(color: Colors.amber[700]!, width: 2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route, color: Colors.amber[900]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coincidenza calcolata (evidenziata per 6 sec)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[950],
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    _highlightedKeys.clear();
                    _coincidenzaAttiva = null;
                  });
                },
              ),
            ],
          ),
          const Divider(height: 16),
          for (final r in coinc.dettagli)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                r,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: r.startsWith('Partenza') ? FontWeight.w600 : FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepSection(
    int index,
    ThemeData theme,
    ColorScheme scheme,
    StatusColors statusColors,
  ) {
    final step = _journey.steps[index];
    final arrivals = _stepArrivals[step.id] ?? [];
    final isLoading = _stepLoading[step.id] ?? false;
    final error = _stepErrors[step.id];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intestazione Tappa
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Fermate: ${step.stopNames.values.join(", ")}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (step.lineNames.length > 1)
                  IconButton(
                    icon: const Icon(Icons.drag_indicator, size: 20),
                    tooltip: 'Ordina priorità mezzi trascinabili',
                    onPressed: () => _apriDialogPriorita(step),
                  ),
              ],
            ),
            const Divider(height: 20),

            if (isLoading && arrivals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null && arrivals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    error,
                    style: TextStyle(color: scheme.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (arrivals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Nessun passaggio previsto nelle prossime ore per le linee selezionate (${step.lineNames.join(", ")}).',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              for (final arr in arrivals)
                _buildArrivalRow(arr, index, theme, scheme, statusColors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArrivalRow(
    _ArrivalItem item,
    int stepIndex,
    ThemeData theme,
    ColorScheme scheme,
    StatusColors statusColors,
  ) {
    final tLine = _lineaPer(item.linea);
    final min = item.passaggio.minutiMancanti(_oraRif);
    final etichetta = item.passaggio.etichettaTempo(_oraRif);
    final isHighlighted = _highlightedKeys.contains(item.key);

    // Controlla se la linea è deviata
    final lineStatus = widget.repo.statusOf(tLine.routeId);
    final hasDeviazione = lineStatus?.activeReports.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _selezionaOrarioETracciaCoincidenze(item, stepIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.amber.withValues(alpha: 0.28)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            border: Border.all(
              color: isHighlighted ? Colors.amber[800]! : scheme.outlineVariant.withValues(alpha: 0.4),
              width: isHighlighted ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              LineBadge(line: tLine, height: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.direzione,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isPreferenziale) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('⭐ Pref.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${item.stopName} (${item.stopCode})',
                          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasDeviazione) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: scheme.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Deviata',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: scheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Chip orario cliccabile
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.amber[700]
                      : (item.passaggio.isRealtime
                          ? statusColors.info.withValues(alpha: 0.15)
                          : scheme.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.passaggio.isRealtime)
                          Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Icon(
                              Icons.sensors,
                              size: 12,
                              color: isHighlighted ? Colors.white : statusColors.info,
                            ),
                          ),
                        Text(
                          etichetta,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isHighlighted
                                ? Colors.white
                                : (item.passaggio.isRealtime ? statusColors.info : scheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                    if (min != null && min > 0)
                      Text(
                        item.passaggio.orario,
                        style: TextStyle(
                          fontSize: 10,
                          color: isHighlighted ? Colors.white70 : scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransferIndicator(int fromIndex, ThemeData theme, ColorScheme scheme) {
    final step = _journey.steps[fromIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_walk, size: 16),
              const SizedBox(width: 6),
              Text(
                'Trasferimento cambio: ~${step.transferMinutes} min a piedi',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TransitLine _lineaPer(String nomeLinea) {
    final tutte = widget.repo.allLines;
    final trovata = tutte.where((l) {
      return l.shortName.toUpperCase() == nomeLinea.toUpperCase() ||
          l.routeId.toUpperCase() == nomeLinea.toUpperCase() ||
          l.routeId.replaceAll('U', '').toUpperCase() == nomeLinea.toUpperCase();
    }).firstOrNull;

    return trovata ??
        TransitLine(
          routeId: nomeLinea,
          shortName: nomeLinea.replaceAll('U', ''),
          routeType: 3,
        );
  }
}

class _ArrivalItem {
  _ArrivalItem({
    required this.key,
    required this.stepId,
    required this.stopId,
    required this.stopCode,
    required this.stopName,
    required this.isPreferenziale,
    required this.linea,
    required this.lineaShort,
    required this.direzione,
    required this.passaggio,
    required this.hasAvviso,
  });

  final String key;
  final String stepId;
  final String stopId;
  final String stopCode;
  final String stopName;
  final bool isPreferenziale;
  final String linea;
  final String lineaShort;
  final String direzione;
  final PassaggioArrivo passaggio;
  final bool hasAvviso;
}

class _CoincidenzaCalcolata {
  _CoincidenzaCalcolata({
    required this.orarioPartenza,
    required this.lineaPartenza,
    required this.dettagli,
  });

  final String orarioPartenza;
  final String lineaPartenza;
  final List<String> dettagli;
}

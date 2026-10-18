import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/models/saved_journey.dart';
import '../core/models/transit.dart';
import '../core/sources/trip_updates_gtt.dart';
import '../data/app_repository.dart';
import 'apple_theme.dart';
import 'journey_editor_screen.dart';
import 'line_badge.dart';
import 'theme.dart';
import 'transit_theme.dart';

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
      backgroundColor: AppleColors.secondarySystemGroupedBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    const Icon(CupertinoIcons.arrow_up_arrow_down, size: 20, color: AppleColors.systemBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Priorità per ${step.title}',
                      style: AppleTypography.headline(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Trascina le linee per cambiare l\'ordine in cui compaiono gli arrivi.',
                  style: AppleTypography.footnote(context),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ReorderableListView(
                    shrinkWrap: true,
                    // ignore: deprecated_member_use
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
                          leading: const Icon(CupertinoIcons.line_horizontal_3, size: 20),
                          title: Text(
                            'Linea $l',
                            style: AppleTypography.callout(context).copyWith(fontWeight: FontWeight.w600),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppleColors.systemBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppleColors.systemBlue, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      backgroundColor: AppleColors.systemGroupedBackground(context),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppleColors.systemBackground(context).withValues(alpha: 0.85),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _journey.name,
              style: AppleTypography.headline(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_journey.cambiCount} ${_journey.cambiCount == 1 ? "cambio" : "cambi"} · ${_journey.steps.length} tratte',
              style: AppleTypography.caption1(context),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.pencil),
            tooltip: 'Modifica percorso',
            onPressed: _apriModifica,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_clockwise),
            tooltip: 'Aggiorna orari',
            onPressed: () => _caricaTutto(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppleColors.systemBlue,
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
                  Icon(CupertinoIcons.clock, size: 14, color: AppleColors.secondaryLabel(context)),
                  const SizedBox(width: 6),
                  Text(
                    'Orari aggiornati alle ${_oraRif.hour.toString().padLeft(2, '0')}:${_oraRif.minute.toString().padLeft(2, '0')}',
                    style: AppleTypography.caption1(context),
                  ),
                  const Spacer(),
                  Text(
                    'Tocca un orario per calcolare la coincidenza',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppleColors.systemBlue,
                      fontWeight: FontWeight.w600,
                    ),
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

    return AppGroupedCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      color: AppleColors.systemOrange.withValues(alpha: 0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.arrow_2_squarepath, color: AppleColors.systemOrange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coincidenza calcolata (evidenziata per 6 sec)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppleColors.systemOrange,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(CupertinoIcons.xmark, size: 16),
                onPressed: () {
                  setState(() {
                    _highlightedKeys.clear();
                    _coincidenzaAttiva = null;
                  });
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: AppleColors.systemOrange.withValues(alpha: 0.3),
            ),
          ),
          for (final r in coinc.dettagli)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                r,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: r.startsWith('Partenza') ? FontWeight.w500 : FontWeight.w600,
                  color: AppleColors.label(context),
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

    return AppGroupedCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intestazione Tappa
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: index == 0
                      ? TransitColors.brandGreen
                      : index == 1
                          ? TransitColors.royalePurple
                          : TransitColors.statusWarning,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: AppleTypography.headline(context),
                    ),
                    Text(
                      'Fermate: ${step.stopNames.values.join(", ")}',
                      style: AppleTypography.caption1(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (step.lineNames.length > 1)
                IconButton(
                  icon: const Icon(CupertinoIcons.arrow_up_arrow_down, size: 18, color: AppleColors.systemBlue),
                  tooltip: 'Ordina priorità mezzi trascinabili',
                  onPressed: () => _apriDialogPriorita(step),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: AppleColors.separator(context),
            ),
          ),

          if (isLoading && arrivals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CupertinoActivityIndicator(radius: 12)),
            )
          else if (error != null && arrivals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  error,
                  style: const TextStyle(color: AppleColors.systemRed, fontSize: 13),
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
                  style: TextStyle(color: AppleColors.secondaryLabel(context), fontSize: 13),
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
        borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
        onTap: () => _selezionaOrarioETracciaCoincidenze(item, stepIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppleColors.systemOrange.withValues(alpha: 0.22)
                : AppleColors.tertiarySystemGroupedBackground(context),
            border: Border.all(
              color: isHighlighted
                  ? AppleColors.systemOrange
                  : AppleColors.separator(context),
              width: isHighlighted ? 1.5 : 0.5,
            ),
            borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
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
                            style: AppleTypography.callout(context).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isPreferenziale) ...[
                          const SizedBox(width: 6),
                          const StatusPill(
                            text: 'Pref.',
                            color: AppleColors.systemOrange,
                            icon: CupertinoIcons.star_fill,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${item.stopName} (${item.stopCode})',
                          style: AppleTypography.caption1(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasDeviazione) ...[
                          const SizedBox(width: 6),
                          const StatusPill(
                            text: 'Deviata',
                            color: AppleColors.systemRed,
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
                      ? AppleColors.systemOrange
                      : (item.passaggio.isRealtime
                          ? AppleColors.systemBlue.withValues(alpha: 0.12)
                          : AppleColors.secondarySystemGroupedBackground(context)),
                  borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
                  border: Border.all(
                    color: isHighlighted
                        ? AppleColors.systemOrange
                        : (item.passaggio.isRealtime
                            ? AppleColors.systemBlue.withValues(alpha: 0.25)
                            : AppleColors.separator(context)),
                    width: 0.5,
                  ),
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
                              color: isHighlighted ? Colors.white : AppleColors.systemBlue,
                            ),
                          ),
                        Text(
                          etichetta,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isHighlighted
                                ? Colors.white
                                : (item.passaggio.isRealtime ? AppleColors.systemBlue : AppleColors.label(context)),
                          ),
                        ),
                      ],
                    ),
                    if (min != null && min > 0)
                      Text(
                        item.passaggio.orario,
                        style: TextStyle(
                          fontSize: 10,
                          color: isHighlighted ? Colors.white70 : AppleColors.secondaryLabel(context),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppleColors.secondarySystemGroupedBackground(context),
            borderRadius: BorderRadius.circular(TransitSizes.radiusPill),
            border: Border.all(color: AppleColors.separator(context), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_walk, size: 15, color: TransitColors.brandGreen),
              const SizedBox(width: 6),
              Text(
                'Trasferimento cambio: ~${step.transferMinutes} min a piedi',
                style: AppleTypography.footnote(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppleColors.label(context),
                ),
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

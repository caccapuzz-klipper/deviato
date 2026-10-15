import 'package:flutter/material.dart';

import '../core/models/saved_journey.dart';
import '../core/pipeline/stop_search.dart';
import '../core/text/display_names.dart';
import '../data/app_repository.dart';
import 'journey_stop_picker.dart';

/// Schermata per creare o modificare una pagina di salvataggio percorsi con cambi multipli (fino a 3 cambi).
class JourneyEditorScreen extends StatefulWidget {
  const JourneyEditorScreen({
    required this.repo,
    this.initialJourney,
    super.key,
  });

  final AppRepository repo;
  final SavedJourneyPage? initialJourney;

  @override
  State<JourneyEditorScreen> createState() => _JourneyEditorScreenState();
}

class _JourneyEditorScreenState extends State<JourneyEditorScreen> {
  late final TextEditingController _nameController;
  late int _cambiCount; // 1, 2, o 3 cambi
  late List<_StepDraft> _steps;

  @override
  void initState() {
    super.initState();
    final init = widget.initialJourney;
    if (init != null) {
      _nameController = TextEditingController(text: init.name);
      _cambiCount = init.cambiCount.clamp(1, 3);
      _steps = [
        for (final s in init.steps)
          _StepDraft(
            id: s.id,
            title: s.title,
            stopIds: s.stopIds.toList(),
            stopCodes: Map<String, String>.from(s.stopCodes),
            stopNames: Map<String, String>.from(s.stopNames),
            preferenzialeStopId: s.preferenzialeStopId,
            lineNames: s.lineNames.toList(),
            transferMinutes: s.transferMinutes,
            priorityOrder: s.priorityOrder.toList(),
          ),
      ];
    } else {
      _nameController = TextEditingController(text: 'Mio Percorso');
      _cambiCount = 2; // Default a 2 cambi come richiesto nell'esempio
      _steps = _creaTappeVuote(_cambiCount);
    }
    _allineaNumeroTappe();
  }

  List<_StepDraft> _creaTappeVuote(int cambi) {
    // Numero di tappe = cambi + 1 (Partenza + N cambi)
    final totale = cambi + 1;
    return List.generate(totale, (i) {
      final title = i == 0 ? 'Partenza (1ª Tratta)' : '$i° Cambio';
      return _StepDraft(
        id: 'step_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: title,
        stopIds: [],
        stopCodes: {},
        stopNames: {},
        preferenzialeStopId: null,
        lineNames: [],
        transferMinutes: 5,
        priorityOrder: [],
      );
    });
  }

  void _allineaNumeroTappe() {
    final desiderate = _cambiCount + 1;
    while (_steps.length < desiderate) {
      final i = _steps.length;
      final title = i == 0 ? 'Partenza (1ª Tratta)' : '$i° Cambio';
      _steps.add(_StepDraft(
        id: 'step_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: title,
        stopIds: [],
        stopCodes: {},
        stopNames: {},
        preferenzialeStopId: null,
        lineNames: [],
        transferMinutes: 5,
        priorityOrder: [],
      ));
    }
    while (_steps.length > desiderate) {
      _steps.removeLast();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _cambiaNumeroCambi(int nuoviCambi) {
    setState(() {
      _cambiCount = nuoviCambi;
      _allineaNumeroTappe();
    });
  }

  Future<void> _aggiungiFermata(int stepIndex) async {
    final f = await showJourneyStopPicker(context, widget.repo);
    if (f == null || !mounted) return;

    final draft = _steps[stepIndex];
    final stopId = f.stop.id;
    final code = f.stop.code ?? stopId;
    final name = DisplayNames.stop(f.stop);

    setState(() {
      if (!draft.stopIds.contains(stopId)) {
        draft.stopIds.add(stopId);
        draft.stopCodes[stopId] = code;
        draft.stopNames[stopId] = name;
        draft.preferenzialeStopId ??= stopId;
      }

      // Estrai le linee che passano da questa fermata e aggiungile se non già presenti
      for (final p in f.passaggi) {
        final shortName = p.routeId.replaceAll('U', '');
        if (!draft.lineNames.contains(shortName)) {
          draft.lineNames.add(shortName);
        }
        if (!draft.priorityOrder.contains(shortName)) {
          draft.priorityOrder.add(shortName);
        }
      }
    });
  }

  void _salvaPercorso() {
    final nome = _nameController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un nome per questo percorso salvato')),
      );
      return;
    }

    for (var i = 0; i < _steps.length; i++) {
      final s = _steps[i];
      if (s.stopIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aggiungi almeno una fermata per ${s.title}')),
        );
        return;
      }
      if (s.lineNames.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seleziona almeno un mezzo/linea per ${s.title}')),
        );
        return;
      }
    }

    final savedPage = SavedJourneyPage(
      id: widget.initialJourney?.id ?? 'journey_${DateTime.now().millisecondsSinceEpoch}',
      name: nome,
      cambiCount: _cambiCount,
      steps: [
        for (final s in _steps)
          SavedCambioStep(
            id: s.id,
            title: s.title,
            stopIds: s.stopIds,
            stopCodes: s.stopCodes,
            stopNames: s.stopNames,
            preferenzialeStopId: s.preferenzialeStopId,
            lineNames: s.lineNames,
            transferMinutes: s.transferMinutes,
            priorityOrder: s.priorityOrder.isNotEmpty ? s.priorityOrder : s.lineNames,
          ),
      ],
      createdAt: DateTime.now(),
    );

    widget.repo.saveJourney(savedPage);
    Navigator.pop(context, savedPage);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialJourney != null ? 'Modifica percorso' : 'Nuovo percorso salvato',
        ),
        actions: [
          FilledButton.icon(
            onPressed: _salvaPercorso,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Salva'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Nome della pagina di salvataggio
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nome pagina di salvataggio',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Es. Casa ➔ Ufficio, Università, Palestra…',
                      prefixIcon: const Icon(Icons.bookmark_border),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: scheme.surface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selezione numero di cambi
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.alt_route, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Quanti cambi devi fare?',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Puoi impostare da 1 a 3 cambi intermedi per arrivare a destinazione.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 1,
                        label: Text('1 cambio\n(2 tratte)', textAlign: TextAlign.center),
                      ),
                      ButtonSegment<int>(
                        value: 2,
                        label: Text('2 cambi\n(3 tratte)', textAlign: TextAlign.center),
                      ),
                      ButtonSegment<int>(
                        value: 3,
                        label: Text('3 cambi\n(4 tratte)', textAlign: TextAlign.center),
                      ),
                    ],
                    selected: {_cambiCount},
                    onSelectionChanged: (val) => _cambiaNumeroCambi(val.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Elenco delle tappe/cambi
          for (var i = 0; i < _steps.length; i++) ...[
            _buildStepCard(i, theme, scheme),
            if (i < _steps.length - 1)
              _buildTransferConnector(i, theme, scheme),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _salvaPercorso,
            icon: const Icon(Icons.check),
            label: const Text('Salva pagina di percorso'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStepCard(int index, ThemeData theme, ColorScheme scheme) {
    final step = _steps[index];
    final isFirst = index == 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titolo della tappa
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isFirst ? '1° Tratta (Partenza)' : '$index° Cambio',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Fermate da visionare
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fermate da visionare:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _aggiungiFermata(index),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Aggiungi fermata'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            if (step.stopIds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nessuna fermata selezionata. Premi "+ Aggiungi fermata" per sceglierne una o più.',
                  style: TextStyle(color: scheme.error, fontSize: 12),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final stopId in step.stopIds)
                    _buildStopChip(index, stopId, theme, scheme),
                ],
              ),
            const SizedBox(height: 16),

            // Mezzi / Linee da visionare
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mezzi / Linee da visionare:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (step.lineNames.length > 1)
                  TextButton.icon(
                    onPressed: () => _apriDialogPriorita(index),
                    icon: const Icon(Icons.drag_indicator, size: 16),
                    label: const Text('Ordina priorità'),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
              ],
            ),
            if (step.lineNames.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aggiungi una fermata per selezionare automaticamente le linee in transito.',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final line in step.lineNames)
                    FilterChip(
                      selected: true,
                      label: Text(line),
                      onSelected: (_) {
                        setState(() {
                          step.lineNames.remove(line);
                          step.priorityOrder.remove(line);
                        });
                      },
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('Altra linea'),
                    onPressed: () => _chiediLineaManuale(index),
                  ),
                ],
              ),

            // Mostra ordine di priorità
            if (step.priorityOrder.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.low_priority, size: 14, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Priorità arrivi: ${step.priorityOrder.join(" ➔ ")}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStopChip(
    int stepIndex,
    String stopId,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final step = _steps[stepIndex];
    final code = step.codeFor(stopId);
    final name = step.nameFor(stopId);
    final isPreferenziale = step.preferenzialeStopId == stopId;

    return Chip(
      avatar: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          isPreferenziale ? Icons.star : Icons.star_border,
          color: isPreferenziale ? Colors.amber[700] : scheme.onSurfaceVariant,
          size: 18,
        ),
        tooltip: isPreferenziale ? 'Fermata preferenziale' : 'Imposta come preferenziale',
        onPressed: () {
          setState(() {
            step.preferenzialeStopId = stopId;
          });
        },
      ),
      label: Text(
        '$name ($code)${isPreferenziale ? " ⭐" : ""}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: isPreferenziale ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () {
        setState(() {
          step.stopIds.remove(stopId);
          step.stopCodes.remove(stopId);
          step.stopNames.remove(stopId);
          if (step.preferenzialeStopId == stopId) {
            step.preferenzialeStopId = step.stopIds.firstOrNull;
          }
        });
      },
    );
  }

  Widget _buildTransferConnector(int fromIndex, ThemeData theme, ColorScheme scheme) {
    final step = _steps[fromIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.directions_walk, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tempo stimato per raggiungere la fermata successiva:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DropdownButton<int>(
                value: step.transferMinutes,
                underline: const SizedBox(),
                items: [2, 4, 5, 7, 10, 15, 20].map((min) {
                  return DropdownMenuItem<int>(
                    value: min,
                    child: Text(
                      '$min min',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => step.transferMinutes = val);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _chiediLineaManuale(int stepIndex) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aggiungi mezzo / linea'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nome o numero linea',
            hintText: 'Es. 55, 68, 10N, STAR 1',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final nome = ctrl.text.trim().toUpperCase();
              if (nome.isNotEmpty) {
                setState(() {
                  if (!_steps[stepIndex].lineNames.contains(nome)) {
                    _steps[stepIndex].lineNames.add(nome);
                    _steps[stepIndex].priorityOrder.add(nome);
                  }
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  void _apriDialogPriorita(int stepIndex) {
    final step = _steps[stepIndex];
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
                    const Text(
                      'Trascina per ordinare la priorità',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'I mezzi in alto avranno la precedenza nella visualizzazione degli arrivi.',
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
                      setState(() {
                        step.priorityOrder = List<String>.from(items);
                      });
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
}

class _StepDraft {
  _StepDraft({
    required this.id,
    required this.title,
    required this.stopIds,
    required this.stopCodes,
    required this.stopNames,
    this.preferenzialeStopId,
    required this.lineNames,
    this.transferMinutes = 5,
    required this.priorityOrder,
  });

  String id;
  String title;
  List<String> stopIds;
  Map<String, String> stopCodes;
  Map<String, String> stopNames;
  String? preferenzialeStopId;
  List<String> lineNames;
  int transferMinutes;
  List<String> priorityOrder;

  String codeFor(String stopId) => stopCodes[stopId] ?? stopId;
  String nameFor(String stopId) => stopNames[stopId] ?? 'Fermata $stopId';
}

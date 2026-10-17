import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/models/saved_journey.dart';
import '../core/text/display_names.dart';
import '../data/app_repository.dart';
import 'apple_theme.dart';
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
      backgroundColor: AppleColors.systemGroupedBackground(context),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppleColors.systemBackground(context).withValues(alpha: 0.85),
        title: Text(
          widget.initialJourney != null ? 'Modifica percorso' : 'Nuovo percorso salvato',
          style: AppleTypography.headline(context),
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: _salvaPercorso,
            child: const Text(
              'Salva',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppleColors.systemBlue,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Nome della pagina di salvataggio
          AppGroupedCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOME PERCORSO',
                  style: AppleTypography.sectionHeader(context),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: AppleTypography.body(context),
                  decoration: InputDecoration(
                    hintText: 'Es. Casa ➔ Ufficio, Università…',
                    hintStyle: TextStyle(color: AppleColors.secondaryLabel(context)),
                    prefixIcon: const Icon(CupertinoIcons.bookmark, size: 18, color: AppleColors.systemBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppleColors.separator(context), width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppleColors.separator(context), width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppleColors.systemBlue, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppleColors.tertiarySystemGroupedBackground(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Selezione numero di cambi
          AppGroupedCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.arrow_branch, color: AppleColors.systemBlue, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Quanti cambi devi fare?',
                      style: AppleTypography.headline(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Puoi impostare da 1 a 3 cambi intermedi per arrivare a destinazione.',
                  style: AppleTypography.footnote(context),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _cambiCount,
                    backgroundColor: AppleColors.tertiarySystemGroupedBackground(context),
                    children: const {
                      1: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text('1 cambio\n(2 tratte)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      ),
                      2: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text('2 cambi\n(3 tratte)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      ),
                      3: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text('3 cambi\n(4 tratte)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) _cambiaNumeroCambi(val);
                    },
                  ),
                ),
              ],
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
          CupertinoButton.filled(
            onPressed: _salvaPercorso,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Text('Salva pagina di percorso'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStepCard(int index, ThemeData theme, ColorScheme scheme) {
    final step = _steps[index];
    final isFirst = index == 0;

    return AppGroupedCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titolo della tappa
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppleColors.systemBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isFirst ? '1ª Tratta (Partenza)' : '$index° Cambio',
                  style: AppleTypography.headline(context),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5, color: AppleColors.separator(context)),
          ),

          // Fermate da visionare
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fermate da visionare:',
                style: AppleTypography.callout(context).copyWith(fontWeight: FontWeight.w600),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _aggiungiFermata(index),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(CupertinoIcons.add_circled, size: 16, color: AppleColors.systemBlue),
                    SizedBox(width: 4),
                    Text('Aggiungi', style: TextStyle(fontSize: 13, color: AppleColors.systemBlue)),
                  ],
                ),
              ),
            ],
          ),
          if (step.stopIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nessuna fermata selezionata. Premi "+ Aggiungi" per sceglierne una o più.',
                style: TextStyle(color: AppleColors.systemRed, fontSize: 12),
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
                style: AppleTypography.callout(context).copyWith(fontWeight: FontWeight.w600),
              ),
              if (step.lineNames.length > 1)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _apriDialogPriorita(index),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(CupertinoIcons.arrow_up_arrow_down, size: 15, color: AppleColors.systemBlue),
                      SizedBox(width: 4),
                      Text('Priorità', style: TextStyle(fontSize: 13, color: AppleColors.systemBlue)),
                    ],
                  ),
                ),
            ],
          ),
          if (step.lineNames.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aggiungi una fermata per selezionare automaticamente le linee in transito.',
                style: AppleTypography.footnote(context),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final line in step.lineNames)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppleColors.systemBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
                      border: Border.all(color: AppleColors.systemBlue.withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          line,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppleColors.systemBlue),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              step.lineNames.remove(line);
                              step.priorityOrder.remove(line);
                            });
                          },
                          child: const Icon(CupertinoIcons.xmark_circle_fill, size: 14, color: AppleColors.systemBlue),
                        ),
                      ],
                    ),
                  ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  color: AppleColors.tertiarySystemGroupedBackground(context),
                  borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
                  onPressed: () => _chiediLineaManuale(index),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.add, size: 14, color: AppleColors.systemBlue),
                      const SizedBox(width: 4),
                      Text('Altra linea', style: AppleTypography.footnote(context).copyWith(color: AppleColors.systemBlue)),
                    ],
                  ),
                ),
              ],
            ),

          // Mostra ordine di priorità
          if (step.priorityOrder.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(CupertinoIcons.arrow_right_arrow_left, size: 13, color: AppleColors.systemBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Priorità arrivi: ${step.priorityOrder.join(" ➔ ")}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppleColors.systemBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPreferenziale
            ? AppleColors.systemOrange.withValues(alpha: 0.12)
            : AppleColors.tertiarySystemGroupedBackground(context),
        borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
        border: Border.all(
          color: isPreferenziale
              ? AppleColors.systemOrange.withValues(alpha: 0.35)
              : AppleColors.separator(context),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                step.preferenzialeStopId = stopId;
              });
            },
            child: Icon(
              isPreferenziale ? CupertinoIcons.star_fill : CupertinoIcons.star,
              color: isPreferenziale ? AppleColors.systemOrange : AppleColors.secondaryLabel(context),
              size: 16,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$name ($code)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isPreferenziale ? FontWeight.bold : FontWeight.normal,
              color: AppleColors.label(context),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                step.stopIds.remove(stopId);
                step.stopCodes.remove(stopId);
                step.stopNames.remove(stopId);
                if (step.preferenzialeStopId == stopId) {
                  step.preferenzialeStopId = step.stopIds.firstOrNull;
                }
              });
            },
            child: Icon(CupertinoIcons.xmark, size: 13, color: AppleColors.secondaryLabel(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferConnector(int fromIndex, ThemeData theme, ColorScheme scheme) {
    final step = _steps[fromIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AppGroupedCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: AppleColors.secondarySystemGroupedBackground(context),
        child: Row(
          children: [
            const Icon(Icons.directions_walk, size: 18, color: AppleColors.systemBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tempo stimato per raggiungere la fermata successiva:',
                style: AppleTypography.footnote(context).copyWith(
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
    );
  }

  void _chiediLineaManuale(int stepIndex) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Aggiungi mezzo / linea'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: ctrl,
            placeholder: 'Es. 55, 68, 10N, STAR 1',
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
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
                      'Trascina per ordinare la priorità',
                      style: AppleTypography.headline(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'I mezzi in alto avranno la precedenza nella visualizzazione degli arrivi.',
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
                      setState(() {
                        step.priorityOrder = List<String>.from(items);
                      });
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

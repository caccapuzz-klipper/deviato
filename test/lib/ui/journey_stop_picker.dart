import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/models/transit.dart';
import '../core/pipeline/stop_search.dart';
import '../core/text/display_names.dart';
import '../data/app_repository.dart';
import 'apple_theme.dart';
import 'line_badge.dart';

/// Selettore modale per cercare e aggiungere una fermata a una tappa di un percorso.
Future<FermataCercabile?> showJourneyStopPicker(
  BuildContext context,
  AppRepository repo,
) {
  return showModalBottomSheet<FermataCercabile>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppleColors.secondarySystemGroupedBackground(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _JourneyStopPickerSheet(repo: repo),
    ),
  );
}

class _JourneyStopPickerSheet extends StatefulWidget {
  const _JourneyStopPickerSheet({required this.repo});

  final AppRepository repo;

  @override
  State<_JourneyStopPickerSheet> createState() => _JourneyStopPickerSheetState();
}

class _JourneyStopPickerSheetState extends State<_JourneyStopPickerSheet> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Assicura il caricamento delle fermate di rete
    if (widget.repo.fermateRete == null) {
      widget.repo.caricaFermate();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

    return ListenableBuilder(
      listenable: widget.repo,
      builder: (context, _) {
        final indice = widget.repo.fermateRete;
        final caricando = widget.repo.caricandoFermate;

        final risultati = (indice != null && query.isNotEmpty)
            ? StopSearch.filter(indice, query, max: 40)
            : <FermataCercabile>[];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.placemark, color: AppleColors.systemBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Seleziona una fermata',
                    style: AppleTypography.headline(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                autofocus: true,
                placeholder: 'Cerca per nome o numero di palina…',
                onChanged: (_) => setState(() {}),
                onSuffixTap: () => setState(() => _searchController.clear()),
              ),
            ),
            const SizedBox(height: 8),
            if (caricando)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoActivityIndicator(radius: 10),
                      SizedBox(width: 12),
                      Text('Caricamento elenco fermate GTT…'),
                    ],
                  ),
                ),
              )
            else if (indice == null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(CupertinoIcons.wifi_slash, size: 40, color: AppleColors.systemRed),
                      const SizedBox(height: 8),
                      Text(
                        'Elenco fermate non disponibile offline.',
                        style: AppleTypography.body(context),
                      ),
                      const SizedBox(height: 12),
                      CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        onPressed: () => widget.repo.caricaFermate(forza: true),
                        child: const Text('Riprova a scaricare'),
                      ),
                    ],
                  ),
                ),
              )
            else if (query.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Digita il nome della fermata (es. "Porta Nuova", "Castello") '
                      'oppure il numero di palina impresso sul palo (es. "40").',
                      textAlign: TextAlign.center,
                      style: AppleTypography.footnote(context),
                    ),
                  ),
                ),
              )
            else if (risultati.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Nessuna fermata trovata per "$query".',
                      textAlign: TextAlign.center,
                      style: AppleTypography.footnote(context),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: risultati.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: AppleColors.separator(context),
                  ),
                  itemBuilder: (context, index) {
                    final f = risultati[index];
                    final nome = DisplayNames.stop(f.stop);
                    final codice = f.stop.code;
                    final linee = <TransitLine>[];
                    final visti = <String>{};
                    for (final p in f.passaggi) {
                      if (visti.add(p.routeId)) {
                        final trovata = widget.repo.allLines
                            .where((l) => l.routeId == p.routeId)
                            .firstOrNull;
                        if (trovata != null) {
                          linee.add(trovata);
                        } else {
                          linee.add(TransitLine(
                            routeId: p.routeId,
                            shortName: p.routeId.replaceAll('U', ''),
                          ));
                        }
                      }
                    }

                    return ListTile(
                      title: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: nome,
                              style: AppleTypography.callout(context).copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (codice != null && codice.isNotEmpty)
                              TextSpan(
                                text: '  palina $codice',
                                style: AppleTypography.caption1(context),
                              ),
                          ],
                        ),
                      ),
                      subtitle: linee.isEmpty
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  for (final l in linee.take(8))
                                    LineBadge(line: l, height: 20),
                                  if (linee.length > 8)
                                    Text(
                                      '+${linee.length - 8}',
                                      style: AppleTypography.caption2(context),
                                    ),
                                ],
                              ),
                            ),
                      trailing: const Icon(CupertinoIcons.plus_circle, color: AppleColors.systemBlue, size: 20),
                      onTap: () => Navigator.pop(context, f),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

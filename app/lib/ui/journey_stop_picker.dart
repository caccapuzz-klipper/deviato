import 'package:flutter/material.dart';

import '../core/models/transit.dart';
import '../core/pipeline/stop_search.dart';
import '../core/text/display_names.dart';
import '../data/app_repository.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                  Icon(Icons.signpost_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Seleziona una fermata',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchBar(
                controller: _searchController,
                autoFocus: true,
                hintText: 'Cerca per nome o numero di palina…',
                leading: const Icon(Icons.search),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _searchController.clear());
                      },
                    ),
                ],
                onChanged: (_) => setState(() {}),
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
                      CircularProgressIndicator(strokeWidth: 2),
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
                      const Icon(Icons.cloud_off, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('Elenco fermate non disponibile offline.'),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
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
                      style: TextStyle(color: scheme.onSurfaceVariant),
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
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: risultati.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
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
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (codice != null && codice.isNotEmpty)
                              TextSpan(
                                text: '  palina $codice',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: FontWeight.normal,
                                ),
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
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                      trailing: const Icon(Icons.add_circle_outline),
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

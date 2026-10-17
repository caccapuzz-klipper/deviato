import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/deviation_service.dart';
import '../core/models/saved_stop.dart';
import '../core/models/transit.dart';
import '../core/pipeline/line_search.dart';
import '../core/pipeline/stop_search.dart';
import '../core/text/display_names.dart';
import '../data/app_repository.dart';
import 'apple_theme.dart';
import 'line_badge.dart';
import 'line_screen.dart';
import 'stop_screen.dart';

/// Apre la ricerca delle linee, sopra la schermata da cui la si chiama.
///
/// Un foglio e non una pagina: si aggiunge una linea e si torna dove si
/// era, senza passare dalle impostazioni come prima.
Future<void> showLinePicker(BuildContext context, AppRepository repo) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppleSizes.radiusLg)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: LinePicker(repo: repo),
      ),
    );

/// Cerca fra tutte le linee di GTT, per numero o per via, e fra le
/// fermate, per nome o numero di palina.
///
/// Le fermate dal 03/10/2026: chi aspetta ha davanti il cartello, con il
/// nome e il numero, e sa raramente da che capolinea a che capolinea va
/// la sua linea. Toccandone una si sceglie linea e direzione, e la fermata
/// finisce salvata in home, con la linea se mancava.
class LinePicker extends StatefulWidget {
  const LinePicker({required this.repo, super.key});

  final AppRepository repo;

  @override
  State<LinePicker> createState() => _LinePickerState();
}

class _LinePickerState extends State<LinePicker> {
  final _query = TextEditingController();

  /// La fermata toccata: al posto dei risultati, le sue linee.
  FermataCercabile? _fermata;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _cambiata(String testo) {
    // Le fermate si scaricano alla prima lettera, non all'apertura: chi
    // aggiunge una linea dall'elenco non ne ha bisogno.
    if (testo.trim().isNotEmpty) {
      widget.repo.caricaFermate();
      final trovate = LineSearch.filter(widget.repo.allLines, testo);
      for (final l in trovate.take(5)) {
        if (widget.repo.statusOf(l.routeId) == null) {
          widget.repo.loadLine(l);
        }
      }
    }
    setState(() {});
  }

  Future<void> _apriMappaLinea(TransitLine line) async {
    LineStatus? status = widget.repo.statusOf(line.routeId);
    if (status == null) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Caricamento percorso…'),
                ],
              ),
            ),
          ),
        ),
      );
      status = await widget.repo.loadLine(line);
      if (mounted) Navigator.pop(context);
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LineScreen(
          repo: widget.repo,
          line: line,
        ),
      ),
    );
  }

  Future<void> _salva(FermataCercabile f, String routeId, int dir) async {
    final messenger = ScaffoldMessenger.of(context);
    final nome = DisplayNames.stop(f.stop);
    Navigator.pop(context);
    final ok = await widget.repo.salvaFermataCercata(f.stop, routeId, dir);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '$nome salvata nelle tue fermate'
              : 'Impossibile salvare la fermata. Controlla la connessione '
                    'e riprova.',
        ),
      ),
    );
  }

  void _add(TransitLine line) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    await widget.repo.settings.addLine(line.shortName);
    await widget.repo.addLine(line);
    await widget.repo.refreshAll();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Linea ${line.shortName} aggiunta'),
      ),
    );
  }

  void _remove(TransitLine line) {
    widget.repo.removeLine(line);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Linea ${line.shortName} rimossa'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final f = _fermata;
    if (f != null) {
      // Indietro, anche col gesto o col tasto del telefono, torna ai
      // risultati e non chiude il foglio.
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (fatto, _) {
          if (!fatto) setState(() => _fermata = null);
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: ListenableBuilder(
            listenable: widget.repo,
            builder: (context, _) => _lineeDellaFermata(context, f),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              onChanged: _cambiata,
              decoration: InputDecoration(
                hintText: 'Linea, via, fermata o numero di palina',
                hintStyle: TextStyle(
                  color: AppleColors.secondaryLabel(context),
                  fontSize: 15,
                ),
                prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18),
                        tooltip: 'Cancella',
                        onPressed: () => setState(_query.clear),
                      ),
                filled: true,
                fillColor: AppleColors.tertiarySystemGroupedBackground(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.repo,
              builder: (context, _) => _risultati(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _risultati(BuildContext context) {
    final repo = widget.repo;
    final testo = Theme.of(context).textTheme;
    final secondario = Theme.of(context).colorScheme.onSurfaceVariant;

    if (repo.allLines.isEmpty) {
      // Al primo avvio l'elenco arriva dalla rete: qualche decina di KB.
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (repo.catalogError == null) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Caricamento delle linee…',
                textAlign: TextAlign.center,
                style: testo.bodyMedium,
              ),
            ] else ...[
              Text(
                'Impossibile caricare l\'elenco delle linee. '
                '${repo.catalogError}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: repo.retryCatalog,
                child: const Text('Riprova'),
              ),
            ],
          ],
        ),
      );
    }

    final watchlist = repo.settings.watchlist.map((w) => w.toUpperCase()).toSet();
    bool giaAggiunta(TransitLine l) =>
        watchlist.contains(l.shortName.toUpperCase()) ||
        watchlist.contains(l.routeId.toUpperCase());
    final trovate = LineSearch.filter(repo.allLines, _query.text);
    final cercando = _query.text.trim().isNotEmpty;
    final fermate = cercando && repo.fermateRete != null
        ? StopSearch.filter(repo.fermateRete!, _query.text)
        : const <FermataCercabile>[];
    final attesaFermate =
        cercando && repo.fermateRete == null && repo.caricandoFermate;
    final erroreFermate = cercando && repo.fermateRete == null
        ? repo.erroreFermate
        : null;
    if (trovate.isEmpty &&
        fermate.isEmpty &&
        !attesaFermate &&
        erroreFermate == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Nessun risultato per «${_query.text.trim()}»',
          textAlign: TextAlign.center,
          style: testo.bodyMedium?.copyWith(color: secondario),
        ),
      );
    }

    // Senza ricerca l'elenco intero, diviso per mezzo: 216 righe di fila
    // non si scorrono, e chi cerca un tram sa gia' che lo e'.
    final righe = <Widget>[];
    if (_query.text.trim().isEmpty) {
      for (final (titolo, gruppo) in [
        ('Tram', trovate.where((l) => l.isTram)),
        ('Bus', trovate.where((l) => l.routeType == 3)),
        ('Altre linee', trovate.where((l) => !l.isTram && l.routeType != 3)),
      ]) {
        if (gruppo.isEmpty) continue;
        righe.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(titolo, style: testo.titleSmall),
          ),
        );
        righe.addAll(gruppo.map((l) => _riga(l, giaAggiunta(l))));
      }
    } else {
      // Due gruppi, Linee e Fermate. Con un numero prima le linee («15» e'
      // quasi sempre la linea 15), con delle parole prima le fermate.
      final linee = [
        if (trovate.isNotEmpty) ...[
          _titolo('Linee'),
          ...trovate.map((l) => _riga(l, giaAggiunta(l))),
        ],
      ];
      final soloFermate = [
        if (fermate.isNotEmpty || attesaFermate || erroreFermate != null)
          _titolo('Fermate'),
        if (attesaFermate)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: LinearProgressIndicator(),
          ),
        if (erroreFermate != null)
          ListTile(
            title: Text(erroreFermate),
            trailing: TextButton(
              onPressed: () => repo.caricaFermate(forza: true),
              child: const Text('Riprova'),
            ),
          ),
        ...fermate.map(_rigaFermata),
      ];
      final numero = RegExp(r'^\s*\d').hasMatch(_query.text);
      righe.addAll(
        numero ? [...linee, ...soloFermate] : [...soloFermate, ...linee],
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 24),
      children: righe,
    );
  }

  Widget _titolo(String testo) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(testo, style: AppleTypography.sectionHeader(context)),
  );

  /// Una fermata fra i risultati: nome, numero di palina e le linee che
  /// ci passano.
  Widget _rigaFermata(FermataCercabile f) {
    final perId = {for (final l in widget.repo.allLines) l.routeId: l};
    final linee = <TransitLine>[
      for (final id in {for (final p in f.passaggi) p.routeId}) ?perId[id],
    ];
    return ListTile(
      leading: const SizedBox(
        width: 44,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Icon(CupertinoIcons.placemark, color: AppleColors.systemBlue, size: 22),
        ),
      ),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: DisplayNames.stop(f.stop),
              style: AppleTypography.headline(context).copyWith(fontSize: 15),
            ),
            if (f.stop.code != null)
              TextSpan(
                text: '  ${f.stop.code}',
                style: TextStyle(color: AppleColors.secondaryLabel(context), fontSize: 13),
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
                  for (final l in linee) LineBadge(line: l, height: 22),
                ],
              ),
            ),
      trailing: Icon(CupertinoIcons.chevron_right, size: 14, color: AppleColors.secondaryLabel(context)),
      onTap: () => setState(() => _fermata = f),
    );
  }

  /// Le linee di una fermata, una riga per direzione: si sceglie quella
  /// che si prende e la fermata si salva.
  Widget _lineeDellaFermata(BuildContext context, FermataCercabile f) {
    final repo = widget.repo;
    final testo = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final perId = {for (final l in repo.allLines) l.routeId: l};
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 16, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Indietro',
                onPressed: () => setState(() => _fermata = null),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: DisplayNames.stop(f.stop),
                        style: testo.titleLarge,
                      ),
                      if (f.stop.code != null)
                        TextSpan(
                          text: '  ${f.stop.code}',
                          style: testo.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: FilledButton.tonalIcon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => StopScreen(
                    stop: f.stop,
                    repo: repo,
                    fermataCercabile: f,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.departure_board),
            label: const Text('Orari e arrivi in tempo reale'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Quale linea prendi? La fermata si salva nella home, con la '
            'sua risposta.',
            style: testo.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        for (final p in f.passaggi)
          if (perId[p.routeId] case final l?)
            _rigaPassaggio(f, l, p.directionId),
      ],
    );
  }

  Widget _rigaPassaggio(FermataCercabile f, TransitLine l, int dir) {
    final repo = widget.repo;
    final capolinea = repo.fermateRete?.capolineaDi(l.routeId, dir);
    final salvata = repo.isSaved(
      SavedStop(routeId: l.routeId, directionId: dir, stopId: f.stop.id),
    );
    return ListTile(
      leading: SizedBox(
        width: 60,
        child: Align(
          alignment: Alignment.centerLeft,
          child: LineBadge(line: l, height: 32),
        ),
      ),
      title: Text(
        capolinea == null
            ? 'Linea ${l.shortName}'
            : 'verso ${DisplayNames.direction(capolinea, longName: l.longName)}',
        style: AppleTypography.headline(context).copyWith(fontSize: 15),
      ),
      trailing: salvata
          ? Semantics(
              label: 'Già fra le tue fermate',
              child: const Icon(CupertinoIcons.checkmark_circle_fill, color: AppleColors.systemGreen, size: 22),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.bookmark, color: AppleColors.systemBlue, size: 18),
                const SizedBox(width: 4),
                const Text(
                  'Salva',
                  style: TextStyle(
                    color: AppleColors.systemBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
      onTap: salvata ? null : () => _salva(f, l.routeId, dir),
    );
  }

  Widget _riga(TransitLine line, bool aggiunta) {
    final parti = DisplayNames.routeParts(line.longName ?? '');
    final status = widget.repo.statusOf(line.routeId);
    final isDeviata = status != null && status.activeReports.isNotEmpty;
    final isRegolare = status != null && status.activeReports.isEmpty;

    return ListTile(
      leading: SizedBox(
        width: 60,
        child: Align(
          alignment: Alignment.centerLeft,
          child: LineBadge(line: line, height: 32),
        ),
      ),
      title: Text(parti.route, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parti.qualifier != null)
            Text(
              parti.qualifier!,
              style: TextStyle(color: AppleColors.secondaryLabel(context)),
            ),
          if (isDeviata)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: StatusPill.alert(
                status.allSkippedStops.isNotEmpty
                    ? '${status.allSkippedStops.length} non ${status.allSkippedStops.length == 1 ? "servita" : "servite"}'
                    : 'Deviazione',
              ),
            )
          else if (isRegolare)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: StatusPill.success('Regolare'),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              aggiunta ? CupertinoIcons.star_fill : CupertinoIcons.star,
              color: aggiunta ? AppleColors.systemOrange : AppleColors.secondaryLabel(context),
              size: 20,
            ),
            tooltip: aggiunta ? 'Rimuovi dai preferiti' : 'Aggiungi ai preferiti',
            onPressed: () => aggiunta ? _remove(line) : _add(line),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.map, size: 20),
            tooltip: 'Mappa percorso',
            onPressed: () => _apriMappaLinea(line),
          ),
        ],
      ),
      onTap: aggiunta ? () => _apriMappaLinea(line) : () => _add(line),
    );
  }
}

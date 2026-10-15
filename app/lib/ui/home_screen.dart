import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/geo/projection.dart';
import '../core/models/saved_stop.dart';
import '../core/models/transit.dart';
import '../core/sources/scioperi_mit.dart';
import '../core/pipeline/arrivi_fermata.dart';
import '../core/pipeline/stop_search.dart';
import '../core/text/display_names.dart';
import '../data/app_repository.dart';
import '../data/user_location.dart';
import 'info_screen.dart';
import 'line_badge.dart';
import 'line_picker.dart';
import 'line_screen.dart';
import 'line_tile.dart';
import 'logo.dart';
import 'saved_stop_card.dart';
import 'stop_screen.dart';

/// La home: le fermate che usi, e sotto le linee.
///
/// Si risponde guardando, prima di uscire di casa. Le fermate salvate
/// stanno in cima perche' rispondono alla domanda vera — la MIA fermata
/// e' servita? — mentre una linea dice solo quante ne salta. Le linee si
/// aggiungono da qui, con «+», e si tolgono scorrendo: prima si passava
/// dalle impostazioni, scrivendo il nome a memoria.
class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.repo, super.key});

  final AppRepository repo;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const DeviatoLogo(),
            actions: [
              IconButton(
                icon: const Icon(Icons.near_me_outlined),
                tooltip: 'Fermate vicine',
                onPressed: () => _mostraFermateVicine(context),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Aggiungi una linea',
                onPressed: () => showLinePicker(context, repo),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Informazioni',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => InfoScreen(repo: repo),
                  ),
                ),
              ),
            ],
          ),
          body: _body(context),
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    // `idle` significa che il caricamento non e' ancora partito. Con una
    // watchlist da caricare va mostrato l'avanzamento: altrimenti nei
    // primi istanti la schermata resta bianca senza spiegazioni.
    if (repo.state == LoadState.loading ||
        (repo.state == LoadState.idle && repo.settings.watchlist.isNotEmpty)) {
      return const _Loading();
    }
    if (repo.state == LoadState.error) {
      return _Message(
        icon: Icons.cloud_off,
        title: 'Impossibile caricare le linee',
        detail: repo.error ?? '',
        action: FilledButton(
          onPressed: repo.initialise,
          child: const Text('Riprova'),
        ),
      );
    }

    final lines = repo.lines;
    if (lines.isEmpty) {
      return _Message(
        icon: Icons.directions_bus_outlined,
        title: 'Aggiungi le tue linee',
        detail:
            'Cercale per numero o per via: vedrai subito se sono '
            'deviate.',
        action: FilledButton.icon(
          onPressed: () => showLinePicker(context, repo),
          icon: const Icon(Icons.add),
          label: const Text('Aggiungi una linea'),
        ),
      );
    }

    final byId = {for (final l in lines) l.routeId: l};
    final fermate = [
      for (final s in repo.savedStops)
        if (byId.containsKey(s.routeId)) s,
    ];
    // Una scheda per linea, nell'ordine in cui le fermate sono state
    // salvate: la linea della prima viene prima.
    final perLinea = <String, List<Widget>>{};
    for (var i = 0; i < fermate.length; i++) {
      final riga = _fermata(context, fermate[i], byId[fermate[i].routeId]!, i);
      if (riga != null) (perLinea[fermate[i].routeId] ??= []).add(riga);
    }

    return RefreshIndicator(
      onRefresh: repo.refreshAll,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (repo.error != null)
            _ErrorBanner(message: repo.error!, onClose: repo.clearError),

          if (repo.scioperoInArrivo case final sciopero?)
            _ScioperoBanner(sciopero: sciopero, repo: repo),

          if (fermate.isNotEmpty) ...[
            const _SectionTitle('Le tue fermate'),
            for (final e in perLinea.entries)
              SavedStopsGroup(
                line: byId[e.key]!,
                onOpenLine: repo.statusOf(e.key) == null
                    ? () => repo.refreshLine(byId[e.key]!)
                    : () => _apri(context, byId[e.key]!),
                children: e.value,
              ),
          ] else if (!repo.settings.stopsHintSeen)
            _StopsHint(onClose: repo.dismissStopsHint),

          _LinesHeader(
            lastCheck: _ultimoControllo(lines),
            refreshing: repo.isRefreshingAll,
            failed: repo.offline,
            onRefreshAll: repo.refreshAll,
          ),
          for (final line in lines) _linea(context, line),
          ListTile(
            leading: SizedBox(
              width: 60,
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              'Aggiungi una linea',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            onTap: () => showLinePicker(context, repo),
          ),
        ],
      ),
    );
  }

  /// Il controllo piu' recente fra le linee: quello che dice quanto e'
  /// fresca la lista. Le righe vecchie dicono da sole di quando sono.
  DateTime? _ultimoControllo(List<TransitLine> lines) {
    DateTime? ultimo;
    for (final l in lines) {
      final t = repo.checkedAt(l.routeId);
      if (t != null && (ultimo == null || t.isAfter(ultimo))) ultimo = t;
    }
    return ultimo;
  }

  void _apri(BuildContext context, TransitLine line, {String? stopId}) {
    // Un «Annulla» della home non ha senso nel dettaglio: seguirebbe
    // l'utente in un'altra schermata, sopra la mappa.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            LineScreen(repo: repo, line: line, initialStopId: stopId),
      ),
    );
  }

  void _mostraFermateVicine(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _FermateVicineSheet(repo: repo),
      ),
    );
  }

  Widget? _fermata(
    BuildContext context,
    SavedStop s,
    TransitLine line,
    int posizione,
  ) {
    final risposta = repo.answerFor(s);
    if (risposta == null) return null;
    return Dismissible(
      key: ValueKey('fermata-$s'),
      direction: DismissDirection.endToStart,
      background: const _SwipeBackground(label: 'Rimuovi'),
      onDismissed: (_) {
        repo.unsaveStop(s);
        _conAnnulla(
          context,
          'Fermata rimossa',
          () => repo.restoreSavedStop(s, posizione),
        );
      },
      child: SavedStopRow(
        answer: risposta,
        line: line,
        checking: repo.isChecking(line.routeId),
        // Mai controllata: toccarla la controlla, come una riga della
        // lista. Altrimenti apre la linea, con la fermata gia' scelta.
        onTap: repo.statusOf(line.routeId) == null
            ? () => repo.refreshLine(line)
            : () => _apri(context, line, stopId: s.stopId),
        onOpenArrivals: () {
          final stop = risposta.stop ??
              TransitStop(
                id: s.stopId,
                name: 'Fermata ${s.stopCode ?? s.stopId}',
                code: s.stopCode,
                position: const GeoPoint(45.07, 7.68),
              );
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => StopScreen(stop: stop, repo: repo),
            ),
          );
        },
      ),
    );
  }

  Widget _linea(BuildContext context, TransitLine line) {
    final preparing = repo.isPreparing(line.routeId);
    final checking = repo.isChecking(line.routeId);
    final tile = LineTile(
      line: line,
      status: repo.statusOf(line.routeId),
      checking: checking,
      preparing: preparing,
      watching: repo.isWatching(line.routeId),
      watchedVehicles: repo.liveTracks.length,
      checkedAt: repo.checkedAt(line.routeId),
      // Una riga mai controllata non ha niente da aprire: toccarla la
      // controlla. Prima non succedeva nulla, e una riga che sembra
      // toccabile e non risponde sembra rotta.
      onTap: preparing
          ? null
          : repo.statusOf(line.routeId) == null
          ? () => repo.refreshLine(line)
          : () => _apri(context, line),
    );
    // Non si toglie una linea mentre la si prepara o la si controlla: il
    // controllo finirebbe su una riga che non c'e' piu'.
    if (preparing || checking) return tile;
    return Dismissible(
      key: ValueKey('linea-${line.routeId}'),
      direction: DismissDirection.endToStart,
      background: const _SwipeBackground(label: 'Rimuovi'),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final lettore = MediaQuery.accessibleNavigationOf(context);
        final tolta = await repo.removeLine(line);
        final fermate = tolta.savedStops.length;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            _annullabile(
              switch (fermate) {
                0 => 'Linea ${line.shortName} rimossa',
                1 => 'Linea ${line.shortName} rimossa con la sua fermata',
                _ =>
                  'Linea ${line.shortName} rimossa con le sue $fermate '
                      'fermate',
              },
              () => repo.restoreLine(tolta),
              lettore: lettore,
            ),
          );
      },
      child: tile,
    );
  }

  static void _conAnnulla(
    BuildContext context,
    String testo,
    VoidCallback annulla,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _annullabile(
          testo,
          annulla,
          lettore: MediaQuery.accessibleNavigationOf(context),
        ),
      );
  }

  /// Un avviso in basso con «Annulla».
  ///
  /// Flutter tiene fermo per sempre uno SnackBar che ha un pulsante, finché
  /// qualcuno non lo chiude: «Fermata rimossa» restava lì sopra la home.
  /// Sparisce dopo cinque secondi, tranne con VoiceOver o TalkBack
  /// ([lettore]), dove raggiungere il pulsante richiede più tempo.
  static SnackBar _annullabile(
    String testo,
    VoidCallback annulla, {
    required bool lettore,
  }) => SnackBar(
    content: Text(testo),
    duration: const Duration(seconds: 5),
    persist: lettore,
    action: SnackBarAction(label: 'Annulla', onPressed: annulla),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// «Le tue linee», quando sono state controllate, e il modo di rifarlo.
///
/// Prima era un pulsante flottante in basso a destra, che copriva l'ultima
/// riga e faceva la stessa cosa del trascinamento verso il basso.
class _LinesHeader extends StatelessWidget {
  const _LinesHeader({
    required this.lastCheck,
    required this.refreshing,
    required this.failed,
    required this.onRefreshAll,
  });

  final DateTime? lastCheck;
  final bool refreshing;

  /// L'ultimo tentativo di scaricare non e' riuscito.
  final bool failed;
  final VoidCallback onRefreshAll;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final secondario = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Le tue linee', style: testo.titleSmall),
                Text(
                  _quando(lastCheck),
                  style: testo.bodySmall?.copyWith(color: secondario),
                ),
              ],
            ),
          ),
          // Mentre scarica, una rotella piccola: dura un secondo, e le righe
          // restano quelle di prima finche' non arrivano le nuove.
          //
          // Il pulsante c'e' solo se l'ultimo tentativo non e' riuscito.
          // Negli altri casi i dati si scaricano da soli, aprendo l'app e
          // tornandoci, e si puo' sempre tirare giu' la lista: un
          // «Aggiorna» sempre in vista faceva pensare che i dati fossero
          // vecchi anche quando non lo erano.
          if (refreshing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else if (failed || lastCheck == null)
            TextButton.icon(
              onPressed: onRefreshAll,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Riprova'),
            ),
        ],
      ),
    );
  }

  static String _quando(DateTime? t) {
    if (t == null) return 'Non ancora aggiornate';
    final h =
        '${t.hour.toString().padLeft(2, "0")}:'
        '${t.minute.toString().padLeft(2, "0")}';
    final oggi = DateTime.now();
    final giorni = DateTime(
      oggi.year,
      oggi.month,
      oggi.day,
    ).difference(DateTime(t.year, t.month, t.day)).inDays;
    return switch (giorni) {
      0 => 'Aggiornate alle $h',
      1 => 'Aggiornate ieri alle $h',
      // Anche qui l'ora: senza, un test scritto il 26 falliva dal 28, e
      // «il 26/9» da solo non dice se sono dati del mattino o della sera.
      _ => 'Aggiornate il ${t.day}/${t.month} alle $h',
    };
  }
}

/// Come si salva una fermata: una volta, finche' non la si chiude o se ne
/// salva una.
class _StopsHint extends StatelessWidget {
  const _StopsHint({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      elevation: 0,
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.bookmark_add_outlined,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salva le tue fermate',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Apri una linea e tocca una fermata sulla mappa: qui '
                    'vedrai subito se è servita.',
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: scheme.onSecondaryContainer),
              tooltip: 'Chiudi',
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo sfondo che compare scorrendo una riga verso sinistra.
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.errorContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.cloud_off, color: scheme.onErrorContainer),
        title: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
        trailing: Semantics(
          button: true,
          label: 'Chiudi',
          child: IconButton(
            icon: Icon(Icons.close, color: scheme.onErrorContainer),
            onPressed: onClose,
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(),
            SizedBox(height: 20),
            Text('Caricamento delle linee…', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class _FermateVicineSheet extends StatefulWidget {
  const _FermateVicineSheet({required this.repo});

  final AppRepository repo;

  @override
  State<_FermateVicineSheet> createState() => _FermateVicineSheetState();
}

class _FermateVicineSheetState extends State<_FermateVicineSheet> {
  bool _loading = true;
  String? _errore;
  List<FermataConDistanza> _fermate = const [];

  @override
  void initState() {
    super.initState();
    _localizzaECarica();
  }

  Future<void> _localizzaECarica() async {
    setState(() {
      _loading = true;
      _errore = null;
    });

    final loc = UserLocation();
    final denial = await loc.ensurePermission();
    if (denial != null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errore = UserLocation.explain(denial);
      });
      return;
    }

    final pos = await loc.current();
    if (pos == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errore =
            'Posizione non disponibile. Verifica che il GPS sia attivo e riprova.';
      });
      return;
    }

    if (widget.repo.fermateRete == null) {
      await widget.repo.caricaFermate();
    }

    final indice = widget.repo.fermateRete;
    if (indice == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errore = 'Indice fermate non disponibile. Verifica la connessione.';
      });
      return;
    }

    final vicine = ArriviFermataHelper.fermateVicine(
      indice,
      userLat: pos.lat,
      userLon: pos.lon,
      max: 30,
      raggioMetri: 1500,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _fermate = vicine;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Icon(Icons.near_me, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Fermate nelle vicinanze',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!_loading)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Ricalcola vicinanze',
                  onPressed: _localizzaECarica,
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _buildContent(theme),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Rilevamento posizione e fermate vicine…'),
            ],
          ),
        ),
      );
    }

    if (_errore != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_outlined,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _errore!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _localizzaECarica,
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    if (_fermate.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore_off_outlined,
                  size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Nessuna fermata GTT trovata entro 1,5 km.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final byId = {for (final l in widget.repo.allLines) l.routeId: l};

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _fermate.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
      itemBuilder: (context, i) {
        final item = _fermate[i];
        final f = item.fermata;
        final nome = DisplayNames.stop(f.stop);
        final linee = [
          for (final p in f.passaggi)
            if (byId.containsKey(p.routeId)) byId[p.routeId]!,
        ];

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.distanzaFormattata,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (f.stop.code != null)
                Text('Palina ${f.stop.code}'),
              if (linee.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final l in linee.take(6))
                        LineBadge(line: l, height: 20),
                    ],
                  ),
                ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => StopScreen(
                  stop: f.stop,
                  repo: widget.repo,
                  fermataCercabile: f,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ScioperoBanner extends StatelessWidget {
  const _ScioperoBanner({required this.sciopero, required this.repo});

  final Sciopero sciopero;
  final AppRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOggi = _isStessoGiorno(sciopero.inizio, DateTime.now()) ||
        (DateTime.now().isAfter(sciopero.inizio) &&
            DateTime.now().isBefore(sciopero.fine.add(const Duration(days: 1))));

    final titolo = isOggi
        ? 'Sciopero dei trasporti OGGI'
        : 'Sciopero dei trasporti in arrivo';

    final dataStr = _formattaDate(sciopero.inizio, sciopero.fine);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      color: theme.colorScheme.errorContainer,
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostraDettaglioSciopero(context, sciopero, repo.scioperi),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.onErrorContainer,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titolo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            dataStr,
                            style: TextStyle(
                              color: theme.colorScheme.onError,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sciopero.modalita.isNotEmpty
                          ? '${sciopero.sindacati}: ${sciopero.modalita}'
                          : sciopero.sindacati,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Tocca per fasce orarie e dettagli',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 11,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ],
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

  static bool _isStessoGiorno(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _formattaDate(DateTime inizio, DateTime fine) {
    if (_isStessoGiorno(inizio, fine)) {
      return '${inizio.day}/${inizio.month}';
    }
    return '${inizio.day}/${inizio.month} - ${fine.day}/${fine.month}';
  }

  static void _mostraDettaglioSciopero(
    BuildContext context,
    Sciopero sciopero,
    List<Sciopero> tuttiScioperi,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _ScioperoDettaglioSheet(
          sciopero: sciopero,
          tuttiScioperi: tuttiScioperi,
        ),
      ),
    );
  }
}

class _ScioperoDettaglioSheet extends StatelessWidget {
  const _ScioperoDettaglioSheet({
    required this.sciopero,
    required this.tuttiScioperi,
  });

  final Sciopero sciopero;
  final List<Sciopero> tuttiScioperi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final altriScioperi = tuttiScioperi
        .where((s) => s != sciopero && s.fine.isAfter(DateTime.now()))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Row(
          children: [
            Icon(Icons.campaign, color: theme.colorScheme.error, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sciopero Trasporti',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: theme.colorScheme.errorContainer.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dettaglioVoce(
                  'Data',
                  sciopero.inizio.day == sciopero.fine.day
                      ? '${sciopero.inizio.day}/${sciopero.inizio.month}/${sciopero.inizio.year}'
                      : 'Dal ${sciopero.inizio.day}/${sciopero.inizio.month} al ${sciopero.fine.day}/${sciopero.fine.month}/${sciopero.fine.year}',
                  theme,
                  evidenziato: true,
                ),
                const SizedBox(height: 10),
                _dettaglioVoce(
                  'Sindacati proclamanti',
                  sciopero.sindacati,
                  theme,
                ),
                const SizedBox(height: 10),
                _dettaglioVoce(
                  'Modalità e orari',
                  sciopero.modalita.isNotEmpty ? sciopero.modalita : 'Non specificata',
                  theme,
                  evidenziato: true,
                ),
                if (sciopero.categoria.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _dettaglioVoce('Categoria', sciopero.categoria, theme),
                ],
                if (sciopero.note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _dettaglioVoce('Fasce / Note MIT', sciopero.note, theme),
                ],
                const SizedBox(height: 10),
                _dettaglioVoce(
                  'Rilevanza',
                  sciopero.rilevanza.isNotEmpty ? sciopero.rilevanza : 'TPL',
                  theme,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          leading: const Icon(Icons.open_in_new),
          title: const Text('Verifica sul calendario ufficiale MIT'),
          subtitle: const Text('scioperi.mit.gov.it'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            try {
              await launchUrl(
                Uri.parse(GttConfig.scioperiMitUrl),
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {}
          },
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Nota: i dati provengono dalla Commissione di Garanzia Scioperi / MIT. '
            'Le fasce di garanzia garantite da GTT (solitamente 6:00-9:00 e 12:00-15:00) '
            'e le corse effettivamente cancellate dipendono dall\'adesione del personale. '
            'Verifica sempre gli aggiornamenti su www.gtt.to.it prima di viaggiare.',
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (altriScioperi.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Altri scioperi programmati',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final s in altriScioperi)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${s.inizio.day}/${s.inizio.month}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(
                  s.sindacati,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  s.modalita.isNotEmpty ? s.modalita : s.settore,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  s.rilevanza,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _dettaglioVoce(
    String etichetta,
    String valore,
    ThemeData theme, {
    bool evidenziato = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etichetta.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valore,
          style: TextStyle(
            fontSize: evidenziato ? 15 : 13,
            fontWeight: evidenziato ? FontWeight.bold : FontWeight.normal,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

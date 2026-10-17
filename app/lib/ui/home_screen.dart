import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/deviation_service.dart';
import '../core/geo/projection.dart';
import '../core/models/saved_journey.dart';
import '../core/models/saved_stop.dart';
import '../core/models/transit.dart';
import '../core/sources/scioperi_mit.dart';
import '../core/pipeline/arrivi_fermata.dart';
import '../core/pipeline/line_search.dart';
import '../core/pipeline/stop_answer.dart';
import '../core/pipeline/vehicle_watch.dart';
import '../core/text/display_names.dart';
import '../data/app_repository.dart';
import '../data/user_location.dart';
import 'info_screen.dart';
import 'journey_editor_screen.dart';
import 'line_badge.dart';
import 'line_picker.dart';
import 'line_screen.dart';
import 'logo.dart';
import 'saved_journey_screen.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'package:flutter/cupertino.dart';
import 'apple_theme.dart';

/// La home: le fermate che usi, e sotto le linee.
///
/// Si risponde guardando, prima di uscire di casa. Le fermate salvate
/// stanno in cima perche' rispondono alla domanda vera — la MIA fermata
/// e' servita? — mentre una linea dice solo quante ne salta. Le linee si
/// aggiungono da qui, con «+», e si tolgono scorrendo: prima si passava
/// dalle impostazioni, scrivendo il nome a memoria.
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.repo, super.key});

  final AppRepository repo;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _sezione = 0; // 0: Di maggior interesse, 1: Linee salvate (con fermate), 2: Tutte le linee (mappe)
  final _filtroLinee = TextEditingController();

  @override
  void dispose() {
    _filtroLinee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (context, _) {
        return Scaffold(
          drawer: _buildDrawer(context),
          appBar: AppBar(
            title: const DeviatoLogo(),
            actions: [
              IconButton(
                icon: const Icon(Icons.near_me_outlined),
                tooltip: 'Fermate vicine',
                onPressed: () => _mostraFermateVicine(context),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Cerca linea o fermata',
                onPressed: () => showLinePicker(context, widget.repo),
              ),
              IconButton(
                icon: const Icon(Icons.sensors),
                tooltip: 'Radar bus live',
                onPressed: () => _mostraRadarMezzi(context),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Informazioni',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => InfoScreen(repo: widget.repo),
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

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final repo = widget.repo;
    final percorsiCount = repo.savedJourneys.length;
    final lineeCount = repo.lines.length;
    final fermateCount = repo.savedStops.length;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primaryContainer,
                  scheme.surfaceContainerHighest,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const DeviatoLogo(),
                const SizedBox(height: 8),
                Text(
                  'DeviaTo · GTT Torino',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Mappe, orari in tempo reale e percorsi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.alt_route, color: scheme.primary),
            title: const Text('Pagine di salvataggio (Percorsi)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$percorsiCount ${percorsiCount == 1 ? "percorso con cambi" : "percorsi con cambi"}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$percorsiCount',
                style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer, fontSize: 12),
              ),
            ),
            selected: _sezione == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _sezione = 0);
            },
          ),
          if (repo.savedJourneys.isNotEmpty) ...[
            for (final j in repo.savedJourneys)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.subdirectory_arrow_right, size: 18),
                  title: Text(j.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${j.cambiCount} ${j.cambiCount == 1 ? "cambio" : "cambi"}'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => SavedJourneyScreen(journey: j, repo: widget.repo),
                      ),
                    );
                  },
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => JourneyEditorScreen(repo: widget.repo),
                  ),
                );
              },
              icon: const Icon(Icons.add_road, size: 18),
              label: const Text('Crea nuovo percorso con cambi'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.directions_bus, color: scheme.primary),
            title: const Text('Linee salvate & Fermate', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Esplora fermate e orari con 1 clic'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$lineeCount',
                style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer, fontSize: 12),
              ),
            ),
            selected: _sezione == 1,
            onTap: () {
              Navigator.pop(context);
              setState(() => _sezione = 1);
            },
          ),
          ListTile(
            leading: Icon(Icons.star, color: Colors.amber[700]),
            title: const Text('Fermate di interesse (Rapidi)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$fermateCount ${fermateCount == 1 ? "fermata salvata" : "fermate salvate"}'),
            selected: _sezione == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _sezione = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Tutte le linee (Mappe)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Catalogo completo e percorsi grafici'),
            selected: _sezione == 2,
            onTap: () {
              Navigator.pop(context);
              setState(() => _sezione = 2);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sensors),
            title: const Text('Radar Bus Live (GPS)'),
            subtitle: const Text('Visualizza i mezzi in movimento'),
            onTap: () {
              Navigator.pop(context);
              _mostraRadarMezzi(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.near_me_outlined),
            title: const Text('Fermate vicine a me'),
            subtitle: const Text('Localizzazione con coordinate GPS'),
            onTap: () {
              Navigator.pop(context);
              _mostraFermateVicine(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Cerca linea o fermata'),
            onTap: () {
              Navigator.pop(context);
              showLinePicker(context, widget.repo);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Informazioni & Note di rilascio'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => InfoScreen(repo: widget.repo),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final repo = widget.repo;
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

    final watchlist = repo.settings.watchlist.map((s) => s.toUpperCase()).toSet();
    final lines = repo.lines
        .where((l) =>
            watchlist.contains(l.shortName.toUpperCase()) ||
            watchlist.contains(l.routeId.toUpperCase()))
        .toList();
    final byId = {for (final l in repo.lines) l.routeId: l};
    final fermate = [
      for (final s in repo.savedStops)
        if (byId.containsKey(s.routeId)) s,
    ];

    return RefreshIndicator(
      onRefresh: repo.refreshAll,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (repo.error != null)
            _ErrorBanner(message: repo.error!, onClose: repo.clearError),

          if (repo.scioperoInArrivo case final sciopero?)
            _ScioperoBanner(sciopero: sciopero, repo: repo),

          // Selettore sezioni in stile iOS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _sezione,
                backgroundColor: AppleColors.tertiarySystemGroupedBackground(context),
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('Di interesse', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('Linee salvate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('Tutte le linee', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                },
                onValueChanged: (val) {
                  if (val != null) setState(() => _sezione = val);
                },
              ),
            ),
          ),

          if (_sezione == 0)
            _sezioneMaggiorInteresse(context, fermate, lines, byId)
          else if (_sezione == 1)
            _sezioneLineeSalvate(context, lines)
          else
            _sezioneTutteLeLinee(context),
        ],
      ),
    );
  }

  Widget _sezioneMaggiorInteresse(
    BuildContext context,
    List<SavedStop> fermate,
    List<TransitLine> lines,
    Map<String, TransitLine> byId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scheda in evidenza per inserimento rapido stile Apple
        AppGroupedCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(CupertinoIcons.star_fill, color: AppleColors.systemOrange, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linee e fermate di maggior interesse',
                      style: AppleTypography.headline(context).copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Orari immediati · Controllo deviazioni in tempo reale',
                      style: AppleTypography.caption1(context),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: AppleColors.systemBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
                onPressed: () => showLinePicker(context, widget.repo),
                child: const Text(
                  'Inserisci',
                  style: TextStyle(
                    color: AppleColors.systemBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (fermate.isEmpty && lines.isEmpty)
          AppGroupedCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              children: [
                const Icon(CupertinoIcons.square_stack_3d_up, size: 44, color: AppleColors.systemBlue),
                const SizedBox(height: 12),
                Text(
                  'Aggiungi le tue linee',
                  style: AppleTypography.headline(context).copyWith(fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Scegli le linee o fermate che prendi di solito per consultare '
                  'subito gli orari di arrivo in tempo reale e sapere se sono deviate o regolari.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppleColors.secondaryLabel(context), fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => showLinePicker(context, widget.repo),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Aggiungi una linea'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Fermate di maggior interesse
        if (fermate.isNotEmpty) ...[
          const _SectionTitle('Le tue fermate'),
          for (var i = 0; i < fermate.length; i++)
            if (byId[fermate[i].routeId] case final l?)
              _schedaFermataInteresse(context, fermate[i], l, i),
        ],

        // Linee di maggior interesse
        if (lines.isNotEmpty) ...[
          _LinesHeader(
            lastCheck: _ultimoControllo(lines),
            refreshing: widget.repo.isRefreshingAll,
            failed: widget.repo.offline,
            onRefreshAll: widget.repo.refreshAll,
          ),
          for (final line in lines)
            _schedaLineaInteresse(context, line),
        ],

        // Pagine di salvataggio percorsi con cambi
        _sezionePercorsiSalvati(context),
      ],
    );
  }

  Widget _sezionePercorsiSalvati(BuildContext context) {
    final journeys = widget.repo.savedJourneys;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Pagine di salvataggio (Fino a 3 cambi)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => JourneyEditorScreen(repo: widget.repo),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nuovo percorso'),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ),
        if (journeys.isEmpty)
          Card(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.alt_route, color: scheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Crea i tuoi percorsi con cambi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Salva diverse pagine (es. Casa ➔ Lavoro) con fino a 3 cambi: '
                    'seleziona fermate preferenziali, linee da visionare, tempo a piedi e '
                    'tocca un orario per vedere la coincidenza in highlight.',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => JourneyEditorScreen(repo: widget.repo),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_road),
                    label: const Text('Crea prima pagina percorso'),
                  ),
                ],
              ),
            ),
          )
        else
          for (final j in journeys) _schedaPercorsoSalvato(context, j),
      ],
    );
  }

  Widget _schedaPercorsoSalvato(BuildContext context, SavedJourneyPage j) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => SavedJourneyScreen(journey: j, repo: widget.repo),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.alt_route, color: scheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          j.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${j.cambiCount} ${j.cambiCount == 1 ? "cambio" : "cambi"} · ${j.steps.length} tratte',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      if (val == 'modifica') {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => JourneyEditorScreen(
                              repo: widget.repo,
                              initialJourney: j,
                            ),
                          ),
                        );
                      } else if (val == 'elimina') {
                        widget.repo.removeSavedJourney(j.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Percorso "${j.name}" eliminato')),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'modifica',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Modifica'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'elimina',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Elimina', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Sintesi tappe
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < j.steps.length; i++) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 9,
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${j.steps[i].title}: ${j.steps[i].stopNames.values.join(", ")} '
                              '(${j.steps[i].lineNames.join(", ")})',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (i < j.steps.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.arrow_downward, size: 12, color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => SavedJourneyScreen(journey: j, repo: widget.repo),
                        ),
                      );
                    },
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Apri orari e coincidenze'),
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _schedaFermataInteresse(
    BuildContext context,
    SavedStop s,
    TransitLine line,
    int posizione,
  ) {
    final risposta = widget.repo.answerFor(s);
    if (risposta == null) return const SizedBox.shrink();

    final stop = risposta.stop ??
        TransitStop(
          id: s.stopId,
          name: 'Fermata ${s.stopCode ?? s.stopId}',
          code: s.stopCode,
          position: const GeoPoint(45.07, 7.68),
        );
    final isDeviata = risposta.state == StopState.closed;
    final isClosesLater = risposta.state == StopState.closesLater;
    final isServita = risposta.state == StopState.served;

    final verso = risposta.shape == null
        ? null
        : DisplayNames.direction(
            risposta.shape!.headsign,
            longName: line.longName,
          );

    return Dismissible(
      key: ValueKey('fermata-fav-${s.routeId}-${s.stopId}-${s.directionId}'),
      direction: DismissDirection.endToStart,
      background: const _SwipeBackground(label: 'Rimuovi'),
      onDismissed: (_) {
        widget.repo.unsaveStop(s);
        _conAnnulla(
          context,
          'Fermata rimossa',
          () => widget.repo.restoreSavedStop(s, posizione),
        );
      },
      child: AppGroupedCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => StopScreen(stop: stop, repo: widget.repo),
            ),
          );
        },
        color: isDeviata
            ? (Theme.of(context).brightness == Brightness.dark
                ? const Color(0x1FFF453A)
                : const Color(0x0FFF3B30))
            : AppleColors.secondarySystemGroupedBackground(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LineBadge(line: line, height: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DisplayNames.stop(stop),
                        style: AppleTypography.headline(context).copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (stop.code != null || verso != null)
                        Text(
                          [
                            if (stop.code != null) 'Palina ${stop.code}',
                            if (verso != null) 'verso $verso',
                          ].join(' · '),
                          style: AppleTypography.caption1(context),
                        ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppleColors.secondaryLabel(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Stato fermata
            if (isDeviata)
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppleColors.systemRed,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Fermata non servita per deviazione',
                      style: TextStyle(
                        color: AppleColors.systemRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const StatusPill.alert('Non servita'),
                ],
              )
            else if (isClosesLater)
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppleColors.systemOrange,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      risposta.from == null
                          ? 'Servita, chiuderà a breve'
                          : 'Chiuderà dal ${_data(risposta.from!)}',
                      style: const TextStyle(
                        color: AppleColors.systemOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const StatusPill.warning('In chiusura'),
                ],
              )
            else if (isServita)
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppleColors.systemGreen,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Servita regolarmente',
                      style: TextStyle(
                        color: AppleColors.systemGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const StatusPill.success('Regolare'),
                ],
              ),

            if (risposta.until != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 13),
                child: Text(
                  'Fino al ${_data(risposta.until!)}',
                  style: AppleTypography.caption1(context),
                ),
              ),
            if (risposta.walkTo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 13),
                child: Text(
                  'Sali a: ${DisplayNames.stop(risposta.walkTo.first.stop)} (${risposta.walkTo.first.stop.code ?? ""}) a circa ${risposta.walkTo.first.meters.round()}m',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppleColors.secondaryLabel(context),
                  ),
                ),
              ),

            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => StopScreen(stop: stop, repo: widget.repo),
                      ),
                    );
                  },
                  icon: const Icon(Icons.departure_board, size: 16),
                  label: const Text('Orari in tempo reale'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.map_outlined, size: 18),
                  tooltip: 'Vedi linea su mappa',
                  onPressed: () => _apri(context, line, stopId: s.stopId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _schedaLineaInteresse(BuildContext context, TransitLine line) {
    final status = widget.repo.statusOf(line.routeId);
    final parti = DisplayNames.routeParts(line.longName ?? '');
    final isDeviata = status != null && status.activeReports.isNotEmpty;
    final isRegolare = status != null && status.activeReports.isEmpty;
    final skippedStops = status?.allSkippedStops ?? const [];

    final isWatching = widget.repo.isWatching(line.routeId);
    final watchTracks = isWatching ? widget.repo.liveTracks : const <VehicleTrack>[];

    return Dismissible(
      key: ValueKey('linea-fav-${line.routeId}'),
      direction: DismissDirection.endToStart,
      background: const _SwipeBackground(label: 'Rimuovi'),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final lettore = MediaQuery.accessibleNavigationOf(context);
        final tolta = await widget.repo.removeLine(line);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            _annullabile(
              'Linea ${line.shortName} rimossa',
              () => widget.repo.restoreLine(tolta),
              lettore: lettore,
            ),
          );
      },
      child: AppGroupedCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        onTap: () => _apri(context, line),
        color: isDeviata
            ? (Theme.of(context).brightness == Brightness.dark
                ? const Color(0x1FFF453A)
                : const Color(0x0FFF3B30))
            : AppleColors.secondarySystemGroupedBackground(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LineBadge(line: line, height: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parti.route,
                        style: AppleTypography.headline(context).copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (parti.qualifier != null)
                        Text(
                          parti.qualifier!,
                          style: AppleTypography.caption1(context),
                        ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppleColors.secondaryLabel(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Stato fermate / deviazione
            if (isDeviata)
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppleColors.systemRed,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      skippedStops.isEmpty
                          ? 'Avviso in corso'
                          : (skippedStops.length == 1
                              ? '1 fermata non servita'
                              : '${skippedStops.length} fermate non servite'),
                      style: const TextStyle(
                        color: AppleColors.systemRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (skippedStops.isNotEmpty)
                    StatusPill.alert(
                      '${skippedStops.length} non ${skippedStops.length == 1 ? "servita" : "servite"}',
                    ),
                ],
              )
            else if (isRegolare)
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppleColors.systemGreen,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Percorso regolare',
                      style: TextStyle(
                        color: AppleColors.systemGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const StatusPill.success('Regolare'),
                ],
              ),

            if (status != null &&
                status.activeReports.isNotEmpty &&
                (status.activeReports.first.notice.headline ?? status.activeReports.first.notice.text).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 13),
                child: Text(
                  status.activeReports.first.notice.headline ?? status.activeReports.first.notice.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppleColors.secondaryLabel(context),
                    fontSize: 12,
                  ),
                ),
              ),

            if (isWatching)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0x331C1C1E)
                        : const Color(0x14000000),
                    borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppleColors.systemGreen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        watchTracks.isEmpty
                            ? 'Ricerca bus…'
                            : '${watchTracks.length} bus in tempo reale',
                        style: AppleTypography.footnote(context),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _mostraOrariFermateLinea(context, line, status),
                  icon: const Icon(Icons.departure_board, size: 16),
                  label: const Text('Orari fermate'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () {
                    if (!isWatching) {
                      widget.repo.startWatch(line);
                    }
                    _apri(context, line);
                  },
                  icon: Icon(
                    isWatching ? Icons.sensors_off : Icons.sensors,
                    size: 16,
                  ),
                  label: Text(isWatching ? 'Stop live' : 'Traccia live'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.map_outlined, size: 18),
                  tooltip: 'Mappa',
                  onPressed: () => _apri(context, line),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sezioneLineeSalvate(BuildContext context, List<TransitLine> lines) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          elevation: 0,
          color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.directions_bus, color: scheme.primary, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Linee salvate e fermate',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Tocca qualsiasi fermata della linea per visualizzarne gli orari in tempo reale e se è deviata.',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => showLinePicker(context, widget.repo),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Aggiungi'),
                ),
              ],
            ),
          ),
        ),

        if (lines.isEmpty)
          Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.directions_bus_outlined, size: 48, color: scheme.primary),
                  const SizedBox(height: 12),
                  const Text(
                    'Nessuna linea salvata',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aggiungi le linee che prendi più spesso per visualizzarne '
                    'tutte le fermate in sequenza e cliccarci sopra facilmente per vedere i passaggi in tempo reale.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => showLinePicker(context, widget.repo),
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi linea da seguire'),
                  ),
                ],
              ),
            ),
          )
        else
          for (final line in lines)
            _CardLineaSalvataConFermate(
              line: line,
              repo: widget.repo,
              onApriMappa: () => _apri(context, line),
            ),
      ],
    );
  }

  Widget _sezioneTutteLeLinee(BuildContext context) {
    final repo = widget.repo;
    final scheme = Theme.of(context).colorScheme;
    final colori = StatusColors.of(context);
    final testo = Theme.of(context).textTheme;

    if (repo.allLines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text('Caricamento elenco linee…', style: testo.bodyMedium),
          ],
        ),
      );
    }

    final query = _filtroLinee.text.trim();
    final filtrate = query.isEmpty
        ? repo.allLines
        : LineSearch.filter(repo.allLines, query);
    final giaSalvate = {for (final l in repo.lines) l.routeId};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _filtroLinee,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cerca linea per numero o via…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_filtroLinee.clear),
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        if (filtrate.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Nessuna linea trovata per «$query»',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          )
        else
          for (final l in filtrate) ...[
            Builder(
              builder: (context) {
                final parti = DisplayNames.routeParts(l.longName ?? '');
                final status = repo.statusOf(l.routeId);
                final isDeviata = status != null && status.activeReports.isNotEmpty;
                final isRegolare = status != null && status.activeReports.isEmpty;
                final inFav = giaSalvate.contains(l.routeId);

                return ListTile(
                  leading: SizedBox(
                    width: 60,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: LineBadge(line: l, height: 32),
                    ),
                  ),
                  title: Text(parti.route, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Row(
                    children: [
                      if (isDeviata)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '⚠️ DEVIATA',
                            style: TextStyle(
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        )
                      else if (isRegolare)
                        Text(
                          '🟢 Percorso regolare',
                          style: TextStyle(color: colori.ok, fontSize: 12),
                        )
                      else
                        Text(
                          'Tocca per mappa percorso',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      inFav ? Icons.star : Icons.star_border,
                      color: inFav ? Colors.amber[700] : scheme.onSurfaceVariant,
                    ),
                    tooltip: inFav ? 'Rimuovi dai preferiti' : 'Aggiungi ai preferiti',
                    onPressed: () {
                      if (inFav) {
                        repo.removeLine(l);
                      } else {
                        repo.addLine(l);
                      }
                    },
                  ),
                  onTap: () => _apri(context, l),
                );
              },
            ),
            const Divider(height: 1, indent: 72),
          ],
      ],
    );
  }

  Future<void> _mostraOrariFermateLinea(
    BuildContext context,
    TransitLine line,
    LineStatus? status,
  ) async {
    LineStatus? effettivo = status ?? widget.repo.statusOf(line.routeId);
    if (effettivo == null) {
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
                  Text('Caricamento fermate…'),
                ],
              ),
            ),
          ),
        ),
      );
      effettivo = await widget.repo.loadLine(line);
      if (!context.mounted) return;
      Navigator.pop(context);
    }
    if (effettivo == null || !context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _OrariFermateLineaSheet(
          line: line,
          status: effettivo!,
          repo: widget.repo,
        ),
      ),
    );
  }

  static String _data(DateTime t) =>
      '${t.day.toString().padLeft(2, "0")}/${t.month.toString().padLeft(2, "0")}';

  /// Il controllo piu' recente fra le linee: quello che dice quanto e'
  /// fresca la lista. Le righe vecchie dicono da sole di quando sono.
  DateTime? _ultimoControllo(List<TransitLine> lines) {
    DateTime? ultimo;
    for (final l in lines) {
      final t = widget.repo.checkedAt(l.routeId);
      if (t != null && (ultimo == null || t.isAfter(ultimo))) ultimo = t;
    }
    return ultimo;
  }

  void _apri(BuildContext context, TransitLine line, {String? stopId}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            LineScreen(repo: widget.repo, line: line, initialStopId: stopId),
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
        child: _FermateVicineSheet(repo: widget.repo),
      ),
    );
  }

  void _mostraRadarMezzi(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _RadarMezziSheet(
          repo: widget.repo,
          onApriLinea: (l) {
            Navigator.pop(context);
            _apri(context, l);
          },
        ),
      ),
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

class _CardLineaSalvataConFermate extends StatefulWidget {
  const _CardLineaSalvataConFermate({
    required this.line,
    required this.repo,
    required this.onApriMappa,
  });

  final TransitLine line;
  final AppRepository repo;
  final VoidCallback onApriMappa;

  @override
  State<_CardLineaSalvataConFermate> createState() =>
      _CardLineaSalvataConFermateState();
}

class _CardLineaSalvataConFermateState
    extends State<_CardLineaSalvataConFermate> {
  bool _expanded = true;
  int _dirIndex = 0;
  bool _loading = false;
  final _filtroFermate = TextEditingController();

  @override
  void initState() {
    super.initState();
    _caricaFermateSeNecessario();
  }

  @override
  void dispose() {
    _filtroFermate.dispose();
    super.dispose();
  }

  Future<void> _caricaFermateSeNecessario() async {
    final status = widget.repo.statusOf(widget.line.routeId);
    if (status == null || status.allShapes.isEmpty) {
      if (mounted) setState(() => _loading = true);
      await widget.repo.loadLine(widget.line);
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colori = StatusColors.of(context);
    final status = widget.repo.statusOf(widget.line.routeId);
    final parti = DisplayNames.routeParts(widget.line.longName ?? '');
    final isDeviata = status != null && status.activeReports.isNotEmpty;
    final isRegolare = status != null && status.activeReports.isEmpty;
    final skippedStops = status?.allSkippedStops ?? const [];
    final skippedIds = {for (final s in skippedStops) s.stop.id};

    final shapes = status != null && status.allShapes.isNotEmpty
        ? status.allShapes
        : (status?.shape != null
            ? [status!.shape, if (status.shapeReturn != null) status.shapeReturn!]
            : const <RouteShape>[]);

    final shapeCorrente = shapes.isNotEmpty
        ? shapes[_dirIndex.clamp(0, shapes.length - 1)]
        : null;

    final tutteFermate = shapeCorrente?.stops ?? const <TransitStop>[];
    final q = _filtroFermate.text.trim().toLowerCase();
    final fermateFiltrate = q.isEmpty
        ? tutteFermate
        : tutteFermate.where((f) {
            return f.name.toLowerCase().contains(q) ||
                (f.code != null && f.code!.contains(q));
          }).toList();

    final isWatching = widget.repo.isWatching(widget.line.routeId);
    final watchTracks = isWatching ? widget.repo.liveTracks : const <VehicleTrack>[];

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      elevation: 0,
      color: isDeviata
          ? scheme.errorContainer.withValues(alpha: 0.35)
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDeviata
            ? BorderSide(color: scheme.error, width: 1.5)
            : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intestazione linea
            Row(
              children: [
                LineBadge(line: widget.line, height: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parti.route,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (parti.qualifier != null)
                        Text(
                          parti.qualifier!,
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  tooltip: _expanded ? 'Comprimi fermate' : 'Espandi fermate',
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Stato deviazione linea
            if (isDeviata)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: scheme.onErrorContainer),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ATTENZIONE: LINEA DEVIATA${skippedStops.isNotEmpty ? " (salta ${skippedStops.length} fermate)" : ""}',
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (isRegolare)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colori.ok.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: colori.ok),
                    const SizedBox(width: 6),
                    Text(
                      'REGOLARE · Nessuna deviazione attiva',
                      style: TextStyle(
                        color: colori.ok,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Pulsanti veloci Mappa e Live
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: widget.onApriMappa,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Mappa'),
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () {
                    if (!isWatching) {
                      widget.repo.startWatch(widget.line);
                    }
                    widget.onApriMappa();
                  },
                  icon: Icon(
                    Icons.sensors,
                    size: 16,
                    color: isWatching ? const Color(0xFF00E676) : null,
                  ),
                  label: Text(isWatching ? 'Live (${watchTracks.length})' : 'Radar live'),
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber),
                  tooltip: 'Rimuovi dai preferiti',
                  onPressed: () => widget.repo.removeLine(widget.line),
                ),
              ],
            ),

            // CONTENUTO ESPANSO: FERMATE CLICCABILI
            if (_expanded) ...[
              const Divider(height: 20),
              if (_loading && shapes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(width: 12),
                        Text('Caricamento fermate della linea…'),
                      ],
                    ),
                  ),
                )
              else if (shapes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nessun percorso registrato per questa linea.',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                )
              else ...[
                // Selettore direzione
                if (shapes.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SegmentedButton<int>(
                      segments: [
                        for (var i = 0; i < shapes.length; i++)
                          ButtonSegment<int>(
                            value: i,
                            label: Text(
                              'verso ${DisplayNames.direction(shapes[i].headsign, longName: widget.line.longName)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      selected: {_dirIndex},
                      onSelectionChanged: (val) => setState(() => _dirIndex = val.first),
                    ),
                  ),

                // Filtro rapido fermata
                if (tutteFermate.length > 8)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: _filtroFermate,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cerca fermata per nome o palina…',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _filtroFermate.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => setState(() => _filtroFermate.clear()),
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                // Suggerimento clic
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app_outlined, size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Tocca una fermata per gli orari in tempo reale:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Elenco fermate ordinato
                Container(
                  constraints: const BoxConstraints(maxHeight: 340),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: fermateFiltrate.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('Nessuna fermata corrispondente')),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: fermateFiltrate.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, indent: 40),
                          itemBuilder: (context, i) {
                            final f = fermateFiltrate[i];
                            final isSkipped = skippedIds.contains(f.id);

                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              leading: CircleAvatar(
                                radius: 11,
                                backgroundColor: isSkipped
                                    ? scheme.errorContainer
                                    : scheme.surfaceContainerHighest,
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSkipped ? scheme.error : scheme.onSurface,
                                  ),
                                ),
                              ),
                              title: Text(
                                DisplayNames.stop(f),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isSkipped ? scheme.error : null,
                                  decoration: isSkipped ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  if (f.code != null && f.code!.isNotEmpty)
                                    Text(
                                      'Palina ${f.code}',
                                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                                    ),
                                  if (isSkipped) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '⚠️ Saltata per deviazione',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Icon(
                                Icons.departure_board_outlined,
                                size: 18,
                                color: scheme.primary,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => StopScreen(stop: f, repo: widget.repo),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _OrariFermateLineaSheet extends StatefulWidget {
  const _OrariFermateLineaSheet({
    required this.line,
    required this.status,
    required this.repo,
  });

  final TransitLine line;
  final LineStatus status;
  final AppRepository repo;

  @override
  State<_OrariFermateLineaSheet> createState() => _OrariFermateLineaSheetState();
}

class _OrariFermateLineaSheetState extends State<_OrariFermateLineaSheet> {
  int _dirIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shapes = widget.status.allShapes.isNotEmpty
        ? widget.status.allShapes
        : [
            widget.status.shape,
            if (widget.status.shapeReturn != null) widget.status.shapeReturn!,
          ];
    final shapeCorrente =
        shapes.isNotEmpty ? shapes[_dirIndex.clamp(0, shapes.length - 1)] : null;
    final fermate = shapeCorrente?.stops ?? const <TransitStop>[];
    final skippedIds = {
      for (final s in widget.status.allSkippedStops) s.stop.id,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              LineBadge(line: widget.line, height: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orari e fermate · Linea ${widget.line.shortName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tocca una fermata per gli orari in tempo reale',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (shapes.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedButton<int>(
              segments: [
                for (var i = 0; i < shapes.length; i++)
                  ButtonSegment<int>(
                    value: i,
                    label: Text(
                      'verso ${DisplayNames.direction(shapes[i].headsign, longName: widget.line.longName)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              selected: {_dirIndex},
              onSelectionChanged: (val) => setState(() => _dirIndex = val.first),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: fermate.isEmpty
              ? const Center(child: Text('Nessuna fermata registrata'))
              : ListView.separated(
                  itemCount: fermate.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
                  itemBuilder: (context, i) {
                    final f = fermate[i];
                    final isSkipped = skippedIds.contains(f.id);

                    return ListTile(
                      leading: Icon(
                        isSkipped
                            ? Icons.do_not_disturb_on_outlined
                            : Icons.signpost_outlined,
                        color: isSkipped ? scheme.error : scheme.primary,
                      ),
                      title: Text(
                        DisplayNames.stop(f),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSkipped ? scheme.error : null,
                          decoration: isSkipped ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (f.code != null)
                            Text('Palina ${f.code}'),
                          if (isSkipped)
                            Text(
                              '⚠️ Fermata saltata per deviazione attiva',
                              style: TextStyle(
                                color: scheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.departure_board_outlined),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => StopScreen(stop: f, repo: widget.repo),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
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
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
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
          color: AppleColors.systemRed.withValues(alpha: 0.08),
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

/// Foglio modale per il tracking in tempo reale e radar della rete GTT.
class _RadarMezziSheet extends StatelessWidget {
  const _RadarMezziSheet({
    required this.repo,
    required this.onApriLinea,
  });

  final AppRepository repo;
  final ValueChanged<TransitLine> onApriLinea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colori = StatusColors.of(context);
    final watchingLine = repo.watchingLine;
    final watchingTracks = repo.liveTracks;
    final lines = repo.lines;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sensors,
                    color: Color(0xFF00C853),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Radar Mezzi in Tempo Reale',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Posizioni GPS in tempo reale dai feed GTFS-RT di GTT',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Linea attualmente monitorata
            if (watchingLine != null) ...[
              Card(
                elevation: 0,
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF00E676), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E676),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'OSSERVAZIONE ATTIVA ORA',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.stop_circle_outlined,
                              color: Colors.white70,
                            ),
                            tooltip: 'Interrompi tracking',
                            onPressed: repo.stopWatch,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          LineBadge(line: watchingLine, height: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  watchingLine.longName ??
                                      'Linea ${watchingLine.shortName}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  watchingTracks.isEmpty
                                      ? 'Ricerca bus nel feed GTT…'
                                      : '${watchingTracks.length} ${watchingTracks.length == 1 ? "mezzo" : "mezzi"} sulla mappa',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => onApriLinea(watchingLine),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF9D400),
                            foregroundColor: const Color(0xFF1E1E1E),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Guarda i bus sulla mappa'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              'LE TUE LINEE SALVATE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            if (lines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Non hai ancora salvato linee tra i preferiti.\n'
                    'Aggiungi le tue linee abituali per tracciarle con un tocco.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              for (final l in lines) ...[
                Builder(
                  builder: (context) {
                    final isThisWatching = watchingLine?.routeId == l.routeId;
                    final status = repo.statusOf(l.routeId);
                    final isDeviata =
                        status != null && status.activeReports.isNotEmpty;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isThisWatching
                          ? scheme.primaryContainer.withValues(alpha: 0.2)
                          : scheme.surfaceContainerHighest.withValues(
                              alpha: 0.4,
                            ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isThisWatching
                              ? const Color(0xFF00E676)
                              : scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: ListTile(
                        leading: LineBadge(line: l, height: 28),
                        title: Text(
                          l.longName ?? 'Linea ${l.shortName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            if (isDeviata)
                              Text(
                                '⚠️ DEVIATA',
                                style: TextStyle(
                                  color: scheme.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              )
                            else
                              Text(
                                '🟢 Regolare',
                                style: TextStyle(
                                  color: colori.ok,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        trailing: FilledButton.tonalIcon(
                          onPressed: () {
                            if (!isThisWatching) {
                              repo.startWatch(l);
                            }
                            onApriLinea(l);
                          },
                          icon: Icon(
                            isThisWatching ? Icons.visibility : Icons.sensors,
                            size: 14,
                            color: isThisWatching
                                ? const Color(0xFF00E676)
                                : null,
                          ),
                          label: Text(
                            isThisWatching ? 'In corso' : 'Traccia live',
                          ),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'I dati provengono direttamente dal feed aperto GTFS-Realtime di GTT '
                      '(vehicle_position.aspx) senza intermediari e senza profilazione.',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

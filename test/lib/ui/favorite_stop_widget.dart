import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/geo/projection.dart';
import '../core/models/saved_stop.dart';
import '../core/models/transit.dart';
import '../core/pipeline/stop_search.dart';
import '../core/sources/trip_updates_gtt.dart';
import '../core/text/display_names.dart';
import '../data/app_repository.dart';
import 'apple_theme.dart';
import 'line_badge.dart';
import 'stop_screen.dart';
import 'transit_theme.dart';

/// Dati della fermata impostata come Widget preferito.
class FavoriteWidgetStop {
  const FavoriteWidgetStop({
    required this.id,
    required this.name,
    this.code,
    this.lines = const [],
  });

  final String id;
  final String name;
  final String? code;
  final List<String> lines;

  static const _kId = 'favorite_widget_stop_id';
  static const _kName = 'favorite_widget_stop_name';
  static const _kCode = 'favorite_widget_stop_code';
  static const _kLines = 'favorite_widget_stop_lines';

  static Future<FavoriteWidgetStop?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kId);
    final name = prefs.getString(_kName);
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      return null;
    }
    final code = prefs.getString(_kCode);
    final lines = prefs.getStringList(_kLines) ?? const [];
    return FavoriteWidgetStop(
      id: id,
      name: name,
      code: code,
      lines: lines,
    );
  }

  static Future<void> save({
    required String id,
    required String name,
    String? code,
    List<String> lines = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kId, id);
    await prefs.setString(_kName, name);
    if (code != null && code.isNotEmpty) {
      await prefs.setString(_kCode, code);
    } else {
      await prefs.remove(_kCode);
    }
    await prefs.setStringList(_kLines, lines);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kName);
    await prefs.remove(_kCode);
    await prefs.remove(_kLines);
  }

  static Future<bool> isFavorite(String stopId, [String? stopCode]) async {
    final current = await load();
    if (current == null) return false;
    if (current.id == stopId) return true;
    if (stopCode != null &&
        stopCode.isNotEmpty &&
        current.code != null &&
        current.code == stopCode) {
      return true;
    }
    return false;
  }
}

/// Widget in stile iOS che mostra in evidenza la fermata preferita
/// con orari in tempo reale e minuti mancanti.
class FavoriteStopWidgetCard extends StatefulWidget {
  const FavoriteStopWidgetCard({
    required this.repo,
    this.showWhenEmpty = false,
    super.key,
  });

  final AppRepository repo;
  final bool showWhenEmpty;

  @override
  State<FavoriteStopWidgetCard> createState() => _FavoriteStopWidgetCardState();
}

class _FavoriteStopWidgetCardState extends State<FavoriteStopWidgetCard> {
  final _source = TripUpdatesGttSource();
  FavoriteWidgetStop? _favorite;
  ArriviFermata? _arrivi;
  bool _loading = false;
  DateTime? _ultimoAggiornamento;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _caricaFermata();
    // Aggiornamento automatico ogni 35 secondi
    _refreshTimer = Timer.periodic(const Duration(seconds: 35), (_) {
      if (mounted && _favorite != null) {
        _aggiornaArrivi(_favorite!);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _caricaFermata() async {
    final fav = await FavoriteWidgetStop.load();
    if (!mounted) return;
    setState(() {
      _favorite = fav;
    });
    if (fav != null) {
      await _aggiornaArrivi(fav);
    }
  }

  Future<void> _aggiornaArrivi(FavoriteWidgetStop fav) async {
    final palina = (fav.code != null && fav.code!.isNotEmpty)
        ? fav.code!
        : fav.id.replaceAll(RegExp(r'[^0-9]'), '');
    if (palina.isEmpty) return;

    if (mounted) setState(() => _loading = true);

    try {
      final res = await _source.fetchArriviPalina(palina, stopId: fav.id);
      if (!mounted) return;
      setState(() {
        _arrivi = res;
        _ultimoAggiornamento = DateTime.now();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  TransitLine _lineaPer(String nomeLinea) {
    final tutte = widget.repo.allLines;
    final trovata = tutte.where((l) {
      return l.shortName.toUpperCase() == nomeLinea.toUpperCase() ||
          l.routeId.toUpperCase() == nomeLinea.toUpperCase();
    }).firstOrNull;

    return trovata ??
        TransitLine(
          routeId: nomeLinea,
          shortName: nomeLinea,
          routeType: 3,
        );
  }

  TransitStop _trovaStop(FavoriteWidgetStop fav) {
    for (final s in widget.repo.savedStops) {
      if (s.stopId == fav.id || (fav.code != null && s.stopCode == fav.code)) {
        return TransitStop(
          id: s.stopId,
          name: fav.name,
          code: s.stopCode ?? fav.code,
          position: const GeoPoint(45.07, 7.68),
        );
      }
    }
    return TransitStop(
      id: fav.id,
      name: fav.name,
      code: fav.code,
      position: const GeoPoint(45.07, 7.68),
    );
  }

  void _apriFermata(FavoriteWidgetStop fav) {
    final stop = _trovaStop(fav);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StopScreen(stop: stop, repo: widget.repo),
      ),
    ).then((_) => _caricaFermata());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fav = _favorite;

    if (fav == null) {
      if (widget.showWhenEmpty) {
        return _buildEmptyWidget(context, isDark);
      }
      return const SizedBox.shrink();
    }

    return _buildActiveWidget(context, isDark, fav);
  }

  Widget _buildEmptyWidget(BuildContext context, bool isDark) {
    return AppGroupedCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppleColors.systemBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  CupertinoIcons.square_on_square,
                  size: 16,
                  color: AppleColors.systemBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'WIDGET FERMATA PREFERITA',
                  style: AppleTypography.caption2(context).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppleColors.secondaryLabel(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppleColors.systemBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Nuovo',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppleColors.systemBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Fissa la tua fermata preferita',
            style: AppleTypography.headline(context).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Visualizza subito qui e sulla tua home i prossimi arrivi e i minuti mancanti in tempo reale appena apri l\'app.',
            style: AppleTypography.caption1(context),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppleColors.systemBlue,
            borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
            onPressed: () => showFavoriteStopPicker(context, widget.repo, onSelected: (stop) async {
              await FavoriteWidgetStop.save(
                id: stop.id,
                name: DisplayNames.stop(stop),
                code: stop.code,
              );
              if (mounted) _caricaFermata();
            }),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(CupertinoIcons.plus_circle, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Scegli fermata preferita',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWidget(
    BuildContext context,
    bool isDark,
    FavoriteWidgetStop fav,
  ) {
    final lineeArrivo = _arrivi?.linee ?? const <ArriviLinea>[];
    final palina = fav.code != null && fav.code!.isNotEmpty ? 'Palina ${fav.code}' : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? TransitColors.surfaceDark1 : TransitColors.surfaceLight1,
        borderRadius: BorderRadius.circular(TransitSizes.radiusCard),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : TransitSizes.elevationCard,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TransitSizes.radiusCard),
          onTap: () => _apriFermata(fav),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Widget
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: TransitColors.brandGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        CupertinoIcons.square_on_square,
                        size: 14,
                        color: TransitColors.brandGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'WIDGET FERMATA PREFERITA',
                        style: AppleTypography.caption2(context).copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: TransitColors.secondaryLabel(context),
                        ),
                      ),
                    ),
                    if (_loading)
                      const CupertinoActivityIndicator(radius: 7)
                    else ...[
                      const TransitLiveWaveIcon(size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: TransitColors.greenVibrant,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(
                        CupertinoIcons.ellipsis_circle,
                        size: 18,
                        color: AppleColors.secondaryLabel(context),
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (val) async {
                        if (val == 'cambia') {
                          showFavoriteStopPicker(context, widget.repo, onSelected: (stop) async {
                            await FavoriteWidgetStop.save(
                              id: stop.id,
                              name: DisplayNames.stop(stop),
                              code: stop.code,
                            );
                            if (mounted) _caricaFermata();
                          });
                        } else if (val == 'rimuovi') {
                          await FavoriteWidgetStop.clear();
                          if (mounted) _caricaFermata();
                        } else if (val == 'aggiorna') {
                          _aggiornaArrivi(fav);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'aggiorna',
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.arrow_clockwise, size: 16),
                              SizedBox(width: 8),
                              Text('Aggiorna adesso'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'cambia',
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.arrow_2_squarepath, size: 16),
                              SizedBox(width: 8),
                              Text('Cambia fermata'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'rimuovi',
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.trash, size: 16, color: AppleColors.systemRed),
                              SizedBox(width: 8),
                              Text('Rimuovi widget', style: TextStyle(color: AppleColors.systemRed)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Nome fermata e palina
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        fav.name,
                        style: AppleTypography.headline(context).copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (palina.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        palina,
                        style: AppleTypography.footnote(context).copyWith(
                          color: AppleColors.secondaryLabel(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Lista passaggi live
                if (lineeArrivo.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _loading
                          ? 'Ricerca orari in tempo reale…'
                          : 'Nessun passaggio previsto a breve su questa palina.',
                      style: AppleTypography.caption1(context),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final l in lineeArrivo.take(3)) ...[
                        _buildArrivoRow(context, l),
                        if (l != lineeArrivo.take(3).last)
                          Divider(
                            height: 12,
                            thickness: AppleSizes.hairline,
                            color: AppleColors.separator(context),
                          ),
                      ],
                    ],
                  ),

                const SizedBox(height: 12),

                // Footer widget con link a StopScreen
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _ultimoAggiornamento == null
                          ? 'In aggiornamento…'
                          : 'Agg. ${_ultimoAggiornamento!.hour.toString().padLeft(2, "0")}:${_ultimoAggiornamento!.minute.toString().padLeft(2, "0")}',
                      style: AppleTypography.caption2(context),
                    ),
                    Row(
                      children: [
                        Text(
                          'Tutti gli orari',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppleColors.systemBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 12,
                          color: AppleColors.systemBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrivoRow(BuildContext context, ArriviLinea l) {
    final tLine = _lineaPer(l.linea);
    final p = l.prossimoPassaggio;
    final minuti = p?.minutiMancanti(DateTime.now());
    final orario = p?.orario ?? '';
    final direzione = l.direzioneBreve ?? l.direzione;
    final isImminente = minuti != null && minuti <= 3;

    return Row(
      children: [
        LineBadge(line: tLine, height: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            direzione.isNotEmpty ? 'verso $direzione' : 'In transito',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        if (minuti != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isImminente
                  ? TransitColors.statusGood.withValues(alpha: 0.16)
                  : TransitColors.brandGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(TransitSizes.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isImminente) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: TransitColors.statusGood,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  minuti == 0 ? 'In arrivo' : 'in $minuti min',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isImminente
                        ? TransitColors.statusGood
                        : TransitColors.brandGreen,
                  ),
                ),
              ],
            ),
          )
        else if (orario.isNotEmpty)
          Text(
            orario,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}

/// Modale di selezione per impostare la fermata del Widget
Future<void> showFavoriteStopPicker(
  BuildContext context,
  AppRepository repo, {
  required void Function(TransitStop stop) onSelected,
}) async {
  final savedStops = repo.savedStops;
  final byId = {for (final l in repo.lines) l.routeId: l};

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppleColors.secondarySystemGroupedBackground(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(TransitSizes.radiusBottomSheet)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: _FavoriteStopPickerSheet(
            repo: repo,
            savedStops: savedStops,
            byId: byId,
            onChosen: (stop) {
              Navigator.pop(sheetContext);
              onSelected(stop);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Fermata "${DisplayNames.stop(stop)}" impostata nel Widget!',
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

class _FavoriteStopPickerSheet extends StatefulWidget {
  const _FavoriteStopPickerSheet({
    required this.repo,
    required this.savedStops,
    required this.byId,
    required this.onChosen,
  });

  final AppRepository repo;
  final List<SavedStop> savedStops;
  final Map<String, TransitLine> byId;
  final ValueChanged<TransitStop> onChosen;

  @override
  State<_FavoriteStopPickerSheet> createState() =>
      _FavoriteStopPickerSheetState();
}

class _FavoriteStopPickerSheetState extends State<_FavoriteStopPickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.repo.fermateRete == null) {
      widget.repo.caricaFermate();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim();
    final fermateRete = widget.repo.fermateRete;

    List<FermataCercabile> risultatiRicerca = const [];
    if (query.isNotEmpty && fermateRete != null) {
      risultatiRicerca = StopSearch.filter(fermateRete, query, max: 20);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppleColors.systemBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.square_on_square,
                  size: 18,
                  color: AppleColors.systemBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scegli Fermata per il Widget',
                      style: AppleTypography.headline(context),
                    ),
                    Text(
                      'Seleziona una fermata tra quelle salvate o cercala',
                      style: AppleTypography.caption1(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: CupertinoSearchTextField(
            controller: _searchCtrl,
            placeholder: 'Cerca per nome fermata o numero palina…',
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              if (query.isEmpty) ...[
                if (widget.savedStops.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Text(
                      'LE TUE FERMATE SALVATE',
                      style: AppleTypography.caption2(context).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  for (final s in widget.savedStops) ...[
                    Builder(
                      builder: (context) {
                        final answer = widget.repo.answerFor(s);
                        final stop = answer?.stop ??
                            TransitStop(
                              id: s.stopId,
                              name: 'Fermata ${s.stopCode ?? s.stopId}',
                              code: s.stopCode,
                              position: const GeoPoint(45.07, 7.68),
                            );
                        final line = widget.byId[s.routeId];

                        return ListTile(
                          leading: line != null
                              ? LineBadge(line: line, height: 26)
                              : const Icon(CupertinoIcons.placemark),
                          title: Text(
                            DisplayNames.stop(stop),
                            style: AppleTypography.body(context),
                          ),
                          subtitle: Text(
                            stop.code != null ? 'Palina ${stop.code}' : 'Fermata',
                            style: AppleTypography.caption1(context),
                          ),
                          trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
                          onTap: () => widget.onChosen(stop),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 56, color: AppleColors.separator(context)),
                  ],
                ] else
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Nessuna fermata salvata. Usa la barra di ricerca qui sopra per trovarne una.',
                        textAlign: TextAlign.center,
                        style: AppleTypography.caption1(context),
                      ),
                    ),
                  ),
              ] else ...[
                if (risultatiRicerca.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nessuna fermata trovata per «$query»',
                        style: AppleTypography.body(context),
                      ),
                    ),
                  )
                else
                  for (final fc in risultatiRicerca) ...[
                    Builder(
                      builder: (context) {
                        final lineeNomi = fc.passaggi
                            .map((p) => p.routeId)
                            .toSet()
                            .take(4)
                            .join(', ');
                        return ListTile(
                          leading: const Icon(
                            CupertinoIcons.placemark,
                            color: AppleColors.systemBlue,
                          ),
                          title: Text(
                            DisplayNames.stop(fc.stop),
                            style: AppleTypography.body(context),
                          ),
                          subtitle: Text(
                            'Palina ${fc.stop.code ?? fc.stop.id}${lineeNomi.isNotEmpty ? " · Linee: $lineeNomi" : ""}',
                            style: AppleTypography.caption1(context),
                          ),
                          trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
                          onTap: () => widget.onChosen(fc.stop),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 56, color: AppleColors.separator(context)),
                  ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

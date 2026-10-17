import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/models/saved_stop.dart';
import '../core/models/transit.dart';
import '../core/pipeline/stop_answer.dart';
import '../core/pipeline/stop_search.dart';
import '../core/sources/trip_updates_gtt.dart';
import '../core/text/display_names.dart';
import '../data/app_repository.dart';
import 'apple_theme.dart';
import 'favorite_stop_widget.dart';
import 'line_badge.dart';
import 'theme.dart';

/// Scheda della fermata: prossimi arrivi in tempo reale e programmati.
class StopScreen extends StatefulWidget {
  const StopScreen({
    required this.stop,
    required this.repo,
    this.fermataCercabile,
    super.key,
  });

  final TransitStop stop;
  final AppRepository repo;
  final FermataCercabile? fermataCercabile;

  @override
  State<StopScreen> createState() => _StopScreenState();
}

class _StopScreenState extends State<StopScreen> {
  final _source = TripUpdatesGttSource();
  ArriviFermata? _arrivi;
  bool _loading = false;
  String? _errore;
  DateTime _oraRif = DateTime.now();
  Timer? _timerAutoRefresh;
  bool _isFavoriteWidget = false;

  @override
  void initState() {
    super.initState();
    _carica();
    _controllaSeWidgetPreferito();
    // Aggiorna l'orario di riferimento ogni 30 secondi
    _timerAutoRefresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _oraRif = DateTime.now());
      }
    });
  }

  Future<void> _controllaSeWidgetPreferito() async {
    final isFav = await FavoriteWidgetStop.isFavorite(
      widget.stop.id,
      widget.stop.code,
    );
    if (mounted) setState(() => _isFavoriteWidget = isFav);
  }

  Future<void> _toggleFavoriteWidget() async {
    if (_isFavoriteWidget) {
      await FavoriteWidgetStop.clear();
      if (mounted) {
        setState(() => _isFavoriteWidget = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fermata rimossa dal Widget della Home'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      final code = (widget.stop.code != null && widget.stop.code!.isNotEmpty)
          ? widget.stop.code
          : (_arrivi?.stopCode.isNotEmpty == true ? _arrivi!.stopCode : null);
      await FavoriteWidgetStop.save(
        id: widget.stop.id,
        name: DisplayNames.stop(widget.stop),
        code: code,
      );
      if (mounted) {
        setState(() => _isFavoriteWidget = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fermata "${DisplayNames.stop(widget.stop)}" impostata nel Widget della Home!',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timerAutoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _carica() async {
    var code = widget.stop.code?.trim() ?? '';
    if (code.isEmpty) {
      if (widget.fermataCercabile?.stop.code != null &&
          widget.fermataCercabile!.stop.code!.trim().isNotEmpty) {
        code = widget.fermataCercabile!.stop.code!.trim();
      }
    }
    if (code.isEmpty) {
      final match = widget.repo.fermateRete?.fermate
          .where((f) => f.stop.id == widget.stop.id)
          .firstOrNull;
      if (match?.stop.code != null && match!.stop.code!.trim().isNotEmpty) {
        code = match.stop.code!.trim();
      }
    }
    if (code.isEmpty) {
      final match = RegExp(r'fermata\s+(\d+)', caseSensitive: false)
          .firstMatch(widget.stop.name);
      if (match != null) {
        code = match.group(1)!;
      }
    }
    if (code.isEmpty) {
      final soloNumeri = widget.stop.id.replaceAll(RegExp(r'[^0-9]'), '');
      if (soloNumeri.isNotEmpty) {
        code = soloNumeri;
      } else {
        code = widget.stop.id.trim();
      }
    }

    if (code.isEmpty) {
      setState(() {
        _errore = 'Numero di palina non disponibile per questa fermata.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errore = null;
    });

    try {
      final res = await _source.fetchArriviPalina(code, stopId: widget.stop.id);
      if (!mounted) return;
      setState(() {
        _arrivi = res;
        _oraRif = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errore = 'Impossibile scaricare gli arrivi per la palina $code in tempo reale.\n'
            'Verifica la connessione internet e riprova.';
        _loading = false;
      });
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
          routeType: 3, // default bus
        );
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = StatusColors.of(context);
    final theme = Theme.of(context);
    final stopName = DisplayNames.stop(widget.stop);
    final stopCode = widget.stop.code ?? widget.stop.id;

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
              stopName,
              style: AppleTypography.headline(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (stopCode.isNotEmpty)
              Text(
                'Palina $stopCode',
                style: AppleTypography.caption1(context),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavoriteWidget
                  ? CupertinoIcons.pin_fill
                  : CupertinoIcons.pin,
              color: _isFavoriteWidget ? AppleColors.systemBlue : null,
            ),
            tooltip: _isFavoriteWidget
                ? 'Rimuovi dal Widget preferito'
                : 'Fissa come Widget preferito',
            onPressed: _toggleFavoriteWidget,
          ),
          IconButton(
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CupertinoActivityIndicator(radius: 8),
                  )
                : const Icon(CupertinoIcons.arrow_clockwise),
            tooltip: 'Aggiorna arrivi',
            onPressed: _loading ? null : _carica,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppleColors.systemBlue,
        onRefresh: _carica,
        child: _buildBody(theme, statusColors),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, StatusColors statusColors) {
    if (_loading && _arrivi == null) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    if (_errore != null && _arrivi == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.wifi_slash,
                size: 48,
                color: AppleColors.systemRed,
              ),
              const SizedBox(height: 16),
              Text(
                _errore!,
                textAlign: TextAlign.center,
                style: AppleTypography.body(context),
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: _carica,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    final arrivi = _arrivi;
    final linee = arrivi?.linee ?? const [];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Intestazione fermata in Apple style
        AppGroupedCard(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppleColors.systemBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.placemark,
                  size: 20,
                  color: AppleColors.systemBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arrivi != null && arrivi.stopCode.isNotEmpty
                          ? 'Palina ${arrivi.stopCode}'
                          : (widget.stop.code != null && widget.stop.code!.isNotEmpty
                              ? 'Palina ${widget.stop.code}'
                              : 'Fermata ${widget.stop.name}'),
                      style: AppleTypography.headline(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Linee in transito: ${linee.length}',
                      style: AppleTypography.subheadline(context),
                    ),
                  ],
                ),
              ),
              Text(
                'Agg. ${_oraRif.hour.toString().padLeft(2, '0')}:${_oraRif.minute.toString().padLeft(2, '0')}',
                style: AppleTypography.footnote(context),
              ),
            ],
          ),
        ),

        // Pulsante Widget preferito in stile Apple
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: _isFavoriteWidget
                ? AppleColors.systemBlue.withValues(alpha: 0.12)
                : AppleColors.secondarySystemGroupedBackground(context),
            borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
            onPressed: _toggleFavoriteWidget,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isFavoriteWidget
                      ? CupertinoIcons.checkmark_seal_fill
                      : CupertinoIcons.square_on_square,
                  size: 16,
                  color: _isFavoriteWidget
                      ? AppleColors.systemBlue
                      : AppleColors.secondaryLabel(context),
                ),
                const SizedBox(width: 8),
                Text(
                  _isFavoriteWidget
                      ? 'Fermata impostata nel Widget Home'
                      : 'Fissa come Widget fermata in Home',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isFavoriteWidget
                        ? AppleColors.systemBlue
                        : AppleColors.label(context),
                  ),
                ),
              ],
            ),
          ),
        ),

        ?_buildDeviazioniAvviso(theme, statusColors),

        if (linee.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 44,
                    color: AppleColors.secondaryLabel(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nessun passaggio previsto nelle prossime ore.',
                    style: AppleTypography.body(context).copyWith(
                      color: AppleColors.secondaryLabel(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          for (final l in linee) _buildLineaCard(l, theme, statusColors),

        const SizedBox(height: 16),
        // Nota informativa e fonte
        Center(
          child: Text(
            'Orari in tempo reale e programmati da GTT S.p.A. · CC BY 4.0',
            style: AppleTypography.footnote(context).copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLineaCard(
    ArriviLinea l,
    ThemeData theme,
    StatusColors statusColors,
  ) {
    final tLine = _lineaPer(l.linea);

    return AppGroupedCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LineBadge(line: tLine, height: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.direzione.isNotEmpty ? l.direzione : (l.direzioneBreve ?? ''),
                      style: AppleTypography.headline(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (l.direzioneBreve != null &&
                        l.direzioneBreve != l.direzione &&
                        l.direzioneBreve!.isNotEmpty)
                      Text(
                        l.direzioneBreve!,
                        style: AppleTypography.caption1(context),
                      ),
                  ],
                ),
              ),
              if (l.avviso)
                StatusPill(
                  text: 'Avviso',
                  color: AppleColors.systemOrange,
                  icon: CupertinoIcons.exclamationmark_triangle_fill,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: AppleColors.separator(context),
            ),
          ),
          if (l.passaggi.isEmpty)
            Text(
              'Nessun passaggio recente o pianificato.',
              style: AppleTypography.subheadline(context),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in l.passaggi)
                  _buildPassaggioChip(p, theme, statusColors),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPassaggioChip(
    PassaggioArrivo p,
    ThemeData theme,
    StatusColors statusColors,
  ) {
    final min = p.minutiMancanti(_oraRif);
    final etichetta = p.etichettaTempo(_oraRif);
    final isRt = p.isRealtime;

    final Color chipBg = isRt
        ? AppleColors.systemBlue.withValues(alpha: 0.10)
        : AppleColors.tertiarySystemGroupedBackground(context);

    final Color chipBorder = isRt
        ? AppleColors.systemBlue.withValues(alpha: 0.28)
        : AppleColors.separator(context);

    final Color textColor =
        isRt ? AppleColors.systemBlue : AppleColors.label(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipBg,
        border: Border.all(color: chipBorder, width: 0.5),
        borderRadius: BorderRadius.circular(AppleSizes.radiusSm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRt) ...[
                Icon(Icons.sensors, size: 13, color: textColor),
                const SizedBox(width: 4),
              ],
              Text(
                etichetta,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textColor,
                  letterSpacing: -0.2,
                ),
              ),
              if (min != null && min > 0 && min <= 45) ...[
                const SizedBox(width: 4),
                Text(
                  '(${p.orario})',
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isRt ? 'in tempo reale' : 'programmato',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isRt ? FontWeight.w600 : FontWeight.w400,
              color: isRt ? textColor : AppleColors.secondaryLabel(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildDeviazioniAvviso(ThemeData theme, StatusColors statusColors) {
    final passaggi = widget.fermataCercabile?.passaggi ??
        widget.repo.fermateRete?.fermate
            .where((f) => f.stop.id == widget.stop.id)
            .firstOrNull
            ?.passaggi;
    if (passaggi == null || passaggi.isEmpty) return null;

    final chiuse = <({TransitLine line, StopAnswer answer})>[];

    for (final p in passaggi) {
      final s = SavedStop(
        routeId: p.routeId,
        directionId: p.directionId,
        stopId: widget.stop.id,
        stopCode: widget.stop.code,
      );
      final ans = widget.repo.answerFor(s);
      if (ans != null &&
          (ans.state == StopState.closed || ans.state == StopState.closesLater)) {
        final line = _lineaPer(p.routeId);
        chiuse.add((line: line, answer: ans));
      }
    }

    if (chiuse.isEmpty) return null;

    return AppGroupedCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      color: AppleColors.systemRed.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.slash_circle,
                size: 18,
                color: AppleColors.systemRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fermata interessata da deviazioni',
                  style: TextStyle(
                    color: AppleColors.systemRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final c in chiuse) ...[
            const SizedBox(height: 4),
            Text(
              c.answer.state == StopState.closed
                  ? 'Linea ${c.line.shortName}: fermata non servita${c.answer.until != null ? " fino al ${c.answer.until!.day}/${c.answer.until!.month}" : ""}.'
                  : 'Linea ${c.line.shortName}: chiuderà dal ${c.answer.from?.day}/${c.answer.from?.month}.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppleColors.label(context),
              ),
            ),
            if (c.answer.walkTo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4),
                child: Text(
                  'Dove salire al suo posto: ${DisplayNames.stop(c.answer.walkTo.first.stop)} (${c.answer.walkTo.first.meters.round()} m a piedi).',
                  style: AppleTypography.footnote(context),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

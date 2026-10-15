import 'dart:async';

import 'package:flutter/material.dart';

import '../core/models/saved_stop.dart';
import '../core/models/transit.dart';
import '../core/pipeline/stop_answer.dart';
import '../core/pipeline/stop_search.dart';
import '../core/sources/trip_updates_gtt.dart';
import '../core/text/display_names.dart';
import '../data/app_repository.dart';
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

  @override
  void initState() {
    super.initState();
    _carica();
    // Aggiorna l'orario di riferimento ogni 30 secondi
    _timerAutoRefresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _oraRif = DateTime.now());
      }
    });
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stopName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (stopCode.isNotEmpty)
              Text(
                'Palina $stopCode',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Aggiorna arrivi',
            onPressed: _loading ? null : _carica,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carica,
        child: _buildBody(theme, statusColors),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, StatusColors statusColors) {
    if (_loading && _arrivi == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errore != null && _arrivi == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 56, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _errore!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _carica,
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
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
        // Intestazione fermata
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.signpost_outlined, color: theme.colorScheme.primary),
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Linee in transito: ${linee.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Agg. ${_oraRif.hour.toString().padLeft(2, '0')}:${_oraRif.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_buildDeviazioniAvviso(theme, statusColors) case final card?)
          card,

        if (linee.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nessun passaggio previsto nelle prossime ore.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 11,
            ),
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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LineBadge(line: tLine, height: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.direzione.isNotEmpty ? l.direzione : (l.direzioneBreve ?? ''),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (l.direzioneBreve != null &&
                          l.direzioneBreve != l.direzione &&
                          l.direzioneBreve!.isNotEmpty)
                        Text(
                          l.direzioneBreve!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (l.avviso)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: statusColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          'Avviso',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),
            if (l.passaggi.isEmpty)
              Text(
                'Nessun passaggio recente o pianificato.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
        ? statusColors.info.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    final Color chipBorder = isRt
        ? statusColors.info.withValues(alpha: 0.4)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    final Color textColor =
        isRt ? statusColors.info : theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipBg,
        border: Border.all(color: chipBorder),
        borderRadius: BorderRadius.circular(8),
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
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              if (min != null && min > 0 && min <= 45) ...[
                const SizedBox(width: 4),
                Text(
                  '(${p.orario})',
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.8),
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
              fontWeight: isRt ? FontWeight.w600 : FontWeight.normal,
              color: isRt ? textColor : theme.colorScheme.onSurfaceVariant,
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

    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.6),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_rounded, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Fermata interessata da deviazioni',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (c.answer.walkTo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4),
                  child: Text(
                    'Dove salire al suo posto: ${DisplayNames.stop(c.answer.walkTo.first.stop)} (${c.answer.walkTo.first.meters.round()} m a piedi).',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

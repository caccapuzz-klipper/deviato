import 'package:flutter/material.dart';

import '../core/models/transit.dart';
import 'line_badge.dart';
import 'transit_theme.dart';

/// Scheda di Linea ufficiale di Transit (SPNearbyRouteCollectionViewCell / RouteCard).
/// Sintetizza identità di linea, destinazione e tempo di arrivo glanceable ad alto contrasto.
class TransitRouteCard extends StatelessWidget {
  const TransitRouteCard({
    required this.line,
    required this.directionTitle,
    this.stopSubtitle,
    this.etaMinutes,
    this.etaDisplay,
    this.subsequentMinutes = const [],
    this.isRealTime = true,
    this.isDeviated = false,
    this.statusText,
    this.onTap,
    this.onSwipe,
    this.margin = const EdgeInsets.symmetric(
      horizontal: TransitSizes.spacingBase,
      vertical: 5,
    ),
    super.key,
  });

  final TransitLine line;
  final String directionTitle;
  final String? stopSubtitle;

  /// Minuti mancanti (es. 4)
  final int? etaMinutes;

  /// Stringa personalizzata se non sono minuti numerici (es. "Arrivo", "Adesso", "18:45")
  final String? etaDisplay;

  /// Partenze successive (es. [12, 25])
  final List<int> subsequentMinutes;

  /// Se l'orario e' confermato da tracciamento GPS in tempo reale (onde radio verdi)
  final bool isRealTime;

  /// Se la linea e' deviata o presenta avvisi attivi
  final bool isDeviated;

  /// Testo di stato supplementare (es. "3 fermate non servite")
  final String? statusText;

  final VoidCallback? onTap;
  final VoidCallback? onSwipe;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? TransitColors.surfaceDark1 : TransitColors.surfaceLight1;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(TransitSizes.radiusCard),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : TransitSizes.elevationCard,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TransitSizes.radiusCard),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra laterale di allerta (Transit AlertCell: 4pt rosso o ambra se deviata)
              if (isDeviated)
                Container(
                  width: 5,
                  color: TransitColors.statusDanger,
                ),

              // Contenuto principale scheda
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Blocco Sinistro: Identificatore di Linea (Squircle Badge)
                      LineBadge(line: line, height: 38),

                      const SizedBox(width: 12),

                      // Blocco Centrale: Destinazione & Fermata
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              directionTitle.toUpperCase(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: TransitColors.label(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (stopSubtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                stopSubtitle!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: TransitColors.secondaryLabel(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (statusText != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                statusText!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDeviated
                                      ? TransitColors.statusDanger
                                      : TransitColors.statusGood,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Blocco Destro: Glanceable Countdown ETA & Live Wave
                      _buildEtaBlock(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onSwipe != null) {
      cardContent = Dismissible(
        key: ValueKey('flip-${line.routeId}-$directionTitle'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (_) async {
          onSwipe?.call();
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          color: TransitColors.brandGreen,
          child: const Icon(Icons.swap_horiz, color: Colors.white, size: 28),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: TransitColors.brandGreen,
          child: const Icon(Icons.swap_horiz, color: Colors.white, size: 28),
        ),
        child: cardContent,
      );
    }

    if (onTap != null) {
      cardContent = TransitBouncingButton(
        onTap: onTap,
        child: cardContent,
      );
    }

    return Padding(
      padding: margin,
      child: cardContent,
    );
  }

  Widget _buildEtaBlock(BuildContext context) {
    if (etaMinutes == null && etaDisplay == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            Icons.chevron_right,
            size: 20,
            color: TransitColors.tertiaryLabel(context),
          ),
        ],
      );
    }

    final displayText = etaDisplay ?? '${etaMinutes ?? 0}';
    final isNum = etaMinutes != null && etaDisplay == null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              displayText,
              style: TextStyle(
                fontSize: isNum ? 34 : 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isDeviated
                    ? TransitColors.statusDanger
                    : (isRealTime ? TransitColors.label(context) : TransitColors.secondaryLabel(context)),
              ),
            ),
            if (isNum) ...[
              const SizedBox(width: 3),
              Text(
                'min',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TransitColors.secondaryLabel(context),
                ),
              ),
            ],
            if (isRealTime) ...[
              const SizedBox(width: 4),
              const TransitLiveWaveIcon(size: 15),
            ],
          ],
        ),
        if (subsequentMinutes.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '${subsequentMinutes.map((m) => '$m').join(' • ')} min',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TransitColors.secondaryLabel(context),
            ),
          ),
        ],
      ],
    );
  }
}

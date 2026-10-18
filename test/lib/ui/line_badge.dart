import 'package:flutter/material.dart';

import '../core/models/transit.dart';
import 'transit_theme.dart';

/// Il badge di linea ufficiale nel Transit Design System (Boxed Badge - 04 §2, 05 §1).
///
/// Squircle a curvatura continua 8pt, colore GTFS ufficiale (`route_color`),
/// micro-icona del veicolo (14x14) e contrasto calcolato dinamicamente
/// tra bianco ultra-puro (#FEFEFE) e nero OLED (#010101).
class LineBadge extends StatelessWidget {
  const LineBadge({
    required this.line,
    this.height = 36,
    this.large = false,
    super.key,
  });

  final TransitLine line;
  final double height;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveHeight = large ? 56.0 : height;
    final ufficiale = _parse(line.color);
    final fondo = ufficiale ?? (isDark ? TransitColors.surfaceDark2 : theme.colorScheme.primaryContainer);
    final testo = ufficiale == null
        ? (isDark ? TransitColors.white : theme.colorScheme.onPrimaryContainer)
        : TransitColors.contrastTextColor(fondo);

    final (IconData icona, String mezzo) = line.isTram
        ? (Icons.tram, 'tram')
        : line.isMetro
            ? (Icons.subway, 'metro')
            : (Icons.directions_bus, 'bus');

    // Se lo sfondo è chiaro o pastello, applichiamo un sottile bordo di contrasto (Transit Design 01 §3)
    final needsBorder = fondo.computeLuminance() > 0.55;

    return Semantics(
      label: '$mezzo ${line.shortName}',
      excludeSemantics: true,
      child: Container(
        height: effectiveHeight,
        constraints: BoxConstraints(minWidth: effectiveHeight * 1.3),
        padding: EdgeInsets.symmetric(horizontal: large ? 12 : 7),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(large ? 12.0 : TransitSizes.radiusBadge),
          border: needsBorder
              ? Border.all(
                  color: const Color(0x33000000),
                  width: 1.0,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icona, size: height * 0.42, color: testo),
              const SizedBox(width: 3),
              Text(
                line.shortName,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: height * 0.44,
                  letterSpacing: -0.2,
                  color: testo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color? _parse(String? hex) {
    if (hex == null || hex.length != 6) return null;
    final v = int.tryParse(hex, radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }
}

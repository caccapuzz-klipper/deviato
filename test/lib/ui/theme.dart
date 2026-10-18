import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'transit_theme.dart';

/// I colori semantici ufficiali del Transit Design System:
/// regolare (verde Transit / statusGood), attenzione (arancione / statusWarning),
/// informazione / tempo reale (Transit Green / brandGreen),
/// osservazione / radar live (viola Transit Royale).
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.ok,
    required this.warning,
    required this.info,
    required this.observed,
  });

  final Color ok;
  final Color warning;
  final Color info;

  /// Il percorso visto sui mezzi: viola regale Transit Royale.
  final Color observed;

  static const light = StatusColors(
    ok: TransitColors.statusGood,
    warning: TransitColors.statusWarning,
    info: TransitColors.brandGreen,
    observed: TransitColors.royalePurple,
  );

  static const dark = StatusColors(
    ok: TransitColors.statusGood,
    warning: TransitColors.statusWarning,
    info: TransitColors.brandGreen,
    observed: TransitColors.royalePurple,
  );

  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ?? light;

  @override
  StatusColors copyWith({
    Color? ok,
    Color? warning,
    Color? info,
    Color? observed,
  }) => StatusColors(
    ok: ok ?? this.ok,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    observed: observed ?? this.observed,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      ok: Color.lerp(ok, other.ok, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      observed: Color.lerp(observed, other.observed, t)!,
    );
  }
}

/// Tavolozza ufficiale Transit: Transit Green (#02B875), neri puri OLED (#010101),
/// superfici chiare e scure, elevate secondo Transit Design System 01.
ColorScheme _tavolozzaTransit(Brightness b) => b == Brightness.light
    ? const ColorScheme(
        brightness: Brightness.light,
        primary: TransitColors.brandGreen,
        onPrimary: TransitColors.white,
        primaryContainer: Color(0xFFE0F7EF),
        onPrimaryContainer: Color(0xFF016D45),
        secondary: Color(0xFF8E8E93),
        onSecondary: Colors.white,
        secondaryContainer: TransitColors.surfaceLight2,
        onSecondaryContainer: TransitColors.darkBase,
        tertiary: TransitColors.statusWarning,
        onTertiary: Colors.white,
        error: TransitColors.statusDanger,
        onError: Colors.white,
        errorContainer: Color(0xFFFFEBEA),
        onErrorContainer: Color(0xFFD32F2F),
        surface: TransitColors.surfaceLight1,
        onSurface: TransitColors.darkBase,
        onSurfaceVariant: Color(0xFF6E6E73),
        surfaceDim: Color(0xFFE5E5EA),
        surfaceBright: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Color(0xFFF9F9FB),
        surfaceContainer: Colors.white,
        surfaceContainerHigh: TransitColors.surfaceLight2,
        surfaceContainerHighest: Color(0xFFE5E5EA),
        outline: Color(0x33000000),
        outlineVariant: Color(0x1F000000),
        inverseSurface: TransitColors.surfaceDark1,
        onInverseSurface: Colors.white,
        inversePrimary: TransitColors.greenVibrant,
        shadow: Color(0x14000000),
        scrim: Color(0x40000000),
        surfaceTint: Colors.transparent,
      )
    : const ColorScheme(
        brightness: Brightness.dark,
        primary: TransitColors.brandGreen,
        onPrimary: TransitColors.white,
        primaryContainer: Color(0xFF014D31),
        onPrimaryContainer: Color(0xFF80E2B8),
        secondary: Color(0xFF8E8E93),
        onSecondary: Colors.black,
        secondaryContainer: TransitColors.surfaceDark2,
        onSecondaryContainer: Colors.white,
        tertiary: TransitColors.statusWarning,
        onTertiary: Colors.black,
        error: TransitColors.statusDanger,
        onError: Colors.black,
        errorContainer: Color(0xFF4D100E),
        onErrorContainer: Color(0xFFFF8A80),
        surface: TransitColors.surfaceDark1,
        onSurface: TransitColors.white,
        onSurfaceVariant: Color(0xFF8E8E93),
        surfaceDim: TransitColors.darkBase,
        surfaceBright: TransitColors.surfaceDark2,
        surfaceContainerLowest: TransitColors.darkBase,
        surfaceContainerLow: Color(0xFF141416),
        surfaceContainer: TransitColors.surfaceDark1,
        surfaceContainerHigh: TransitColors.surfaceDark2,
        surfaceContainerHighest: Color(0xFF3A3A3C),
        outline: Color(0x60545458),
        outlineVariant: Color(0x33545458),
        inverseSurface: TransitColors.surfaceLight2,
        onInverseSurface: TransitColors.darkBase,
        inversePrimary: TransitColors.brandGreen,
        shadow: Colors.transparent,
        scrim: Color(0x60000000),
        surfaceTint: Colors.transparent,
      );

/// Il tema dell'app, ottimizzato per il Transit Design System (v6.1.7).
ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = _tavolozzaTransit(brightness);

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    platform: TargetPlatform.iOS,
    scaffoldBackgroundColor: isDark ? TransitColors.darkBase : TransitColors.surfaceLight2,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? TransitColors.darkBase : TransitColors.surfaceLight2,
      foregroundColor: isDark ? TransitColors.white : TransitColors.darkBase,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? TransitColors.white : TransitColors.darkBase,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isDark ? TransitColors.surfaceDark1 : TransitColors.surfaceLight1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TransitSizes.radiusCard),
      ),
    ),
    dividerTheme: DividerThemeData(
      thickness: TransitSizes.hairline,
      space: TransitSizes.hairline,
      color: isDark ? const Color(0x33545458) : const Color(0x26000000),
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: TransitColors.brandGreen,
      scaffoldBackgroundColor: isDark ? TransitColors.darkBase : TransitColors.surfaceLight2,
      barBackgroundColor: isDark ? const Color(0xCC010101) : const Color(0xCCF2F2F7),
    ),
    extensions: [
      isDark ? StatusColors.dark : StatusColors.light,
    ],
  );

  return base.copyWith(textTheme: _scalaTipografica(base.textTheme, isDark));
}

TextTheme _scalaTipografica(TextTheme t, bool isDark) {
  final textColor = isDark ? TransitColors.white : TransitColors.darkBase;
  const subColor = Color(0xFF8E8E93);

  TextStyle s({required double size, required FontWeight weight, double? spacing, Color? color}) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing ?? 0,
      color: color ?? textColor,
    );
  }

  return t.copyWith(
    headlineLarge: s(size: 34, weight: FontWeight.w800, spacing: -0.5),
    headlineMedium: s(size: 28, weight: FontWeight.w700, spacing: -0.4),
    headlineSmall: s(size: 22, weight: FontWeight.w700, spacing: -0.3),
    titleLarge: s(size: 20, weight: FontWeight.w700, spacing: -0.2),
    titleMedium: s(size: 17, weight: FontWeight.w600, spacing: -0.2),
    titleSmall: s(size: 15, weight: FontWeight.w600, spacing: -0.1),
    bodyLarge: s(size: 17, weight: FontWeight.w400, spacing: -0.2),
    bodyMedium: s(size: 15, weight: FontWeight.w400, spacing: -0.1),
    bodySmall: s(size: 13, weight: FontWeight.w400, spacing: 0, color: subColor),
    labelLarge: s(size: 15, weight: FontWeight.w700, spacing: 0, color: TransitColors.brandGreen),
    labelMedium: s(size: 13, weight: FontWeight.w600, spacing: 0.1, color: subColor),
    labelSmall: s(size: 11, weight: FontWeight.w700, spacing: 0.5, color: subColor),
  );
}

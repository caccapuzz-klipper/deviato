import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'apple_theme.dart';

/// I colori semantici in stile Apple Human Interface Guidelines (HIG):
/// regolare (verde), attenzione (arancione), informazione/tempo reale (blu),
/// osservazione/live tracking (viola/indaco).
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

  /// Il percorso visto sui mezzi: viola/indaco iOS.
  final Color observed;

  static const light = StatusColors(
    ok: AppleColors.systemGreen,
    warning: AppleColors.systemOrange,
    info: AppleColors.systemBlue,
    observed: AppleColors.systemPurple,
  );

  static const dark = StatusColors(
    ok: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    info: Color(0xFF0A84FF),
    observed: Color(0xFFBF5AF2),
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

/// Tavolozza iOS nativa: grigio grouped chiarissimo di sistema, card bianche,
/// accento blu iOS per selezioni/pulsanti, e colori semantici chiari.
ColorScheme _tavolozzaApple(Brightness b) => b == Brightness.light
    ? const ColorScheme(
        brightness: Brightness.light,
        primary: AppleColors.systemBlue,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE5F1FF),
        onPrimaryContainer: AppleColors.systemBlue,
        secondary: Color(0xFF8E8E93),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFF2F2F7),
        onSecondaryContainer: Color(0xFF1C1C1E),
        tertiary: AppleColors.systemOrange,
        onTertiary: Colors.white,
        error: AppleColors.systemRed,
        onError: Colors.white,
        errorContainer: Color(0xFFFFE5E5),
        onErrorContainer: Color(0xFFD70015),
        surface: Colors.white,
        onSurface: Color(0xFF000000),
        onSurfaceVariant: Color(0xFF8E8E93),
        surfaceDim: Color(0xFFE5E5EA),
        surfaceBright: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Color(0xFFF9F9FB),
        surfaceContainer: Colors.white,
        surfaceContainerHigh: Color(0xFFF2F2F7),
        surfaceContainerHighest: Color(0xFFE5E5EA),
        outline: Color(0x333C3C43),
        outlineVariant: Color(0x1F3C3C43),
        inverseSurface: Color(0xFF1C1C1E),
        onInverseSurface: Colors.white,
        inversePrimary: Color(0xFF0A84FF),
        shadow: Colors.transparent,
        scrim: Color(0x40000000),
        surfaceTint: Colors.transparent,
      )
    : const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF0A84FF),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF003366),
        onPrimaryContainer: Color(0xFF90CAF9),
        secondary: Color(0xFF8E8E93),
        onSecondary: Colors.black,
        secondaryContainer: Color(0xFF2C2C2E),
        onSecondaryContainer: Colors.white,
        tertiary: Color(0xFFFF9F0A),
        onTertiary: Colors.black,
        error: Color(0xFFFF453A),
        onError: Colors.black,
        errorContainer: Color(0xFF4D0000),
        onErrorContainer: Color(0xFFFFD1D1),
        surface: Color(0xFF1C1C1E),
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFF8E8E93),
        surfaceDim: Color(0xFF161618),
        surfaceBright: Color(0xFF2C2C2E),
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: Color(0xFF121214),
        surfaceContainer: Color(0xFF1C1C1E),
        surfaceContainerHigh: Color(0xFF2C2C2E),
        surfaceContainerHighest: Color(0xFF3A3A3C),
        outline: Color(0x60545458),
        outlineVariant: Color(0x33545458),
        inverseSurface: Color(0xFFF2F2F7),
        onInverseSurface: Color(0xFF1C1C1E),
        inversePrimary: AppleColors.systemBlue,
        shadow: Colors.transparent,
        scrim: Color(0x60000000),
        surfaceTint: Colors.transparent,
      );

/// Il tema dell'app, ottimizzato per l'estetica e l'ergonomia Apple iOS.
ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = _tavolozzaApple(brightness);

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    platform: TargetPlatform.iOS,
    scaffoldBackgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? const Color(0xCC1C1C1E) : const Color(0xCCF2F2F7),
      foregroundColor: isDark ? Colors.white : Colors.black,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black,
        letterSpacing: -0.41,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppleSizes.radiusCard),
      ),
    ),
    dividerTheme: DividerThemeData(
      thickness: AppleSizes.hairline,
      space: AppleSizes.hairline,
      color: isDark ? const Color(0x60545458) : const Color(0x333C3C43),
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: AppleColors.systemBlue,
      scaffoldBackgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      barBackgroundColor: isDark ? const Color(0xCC1C1C1E) : const Color(0xCCF2F2F7),
    ),
    extensions: [
      isDark ? StatusColors.dark : StatusColors.light,
    ],
  );

  return base.copyWith(textTheme: _scalaTipografica(base.textTheme, isDark));
}

TextTheme _scalaTipografica(TextTheme t, bool isDark) {
  final textColor = isDark ? Colors.white : Colors.black;
  final subColor = const Color(0xFF8E8E93);

  TextStyle? s({required double size, required FontWeight weight, double? spacing, Color? color}) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing ?? 0,
      color: color ?? textColor,
    );
  }

  return t.copyWith(
    headlineLarge: s(size: 34, weight: FontWeight.w700, spacing: 0.37),
    headlineMedium: s(size: 28, weight: FontWeight.w700, spacing: 0.36),
    headlineSmall: s(size: 22, weight: FontWeight.w700, spacing: 0.35),
    titleLarge: s(size: 20, weight: FontWeight.w600, spacing: 0.38),
    titleMedium: s(size: 17, weight: FontWeight.w600, spacing: -0.41),
    titleSmall: s(size: 15, weight: FontWeight.w600, spacing: -0.24),
    bodyLarge: s(size: 17, weight: FontWeight.w400, spacing: -0.41),
    bodyMedium: s(size: 15, weight: FontWeight.w400, spacing: -0.24),
    bodySmall: s(size: 13, weight: FontWeight.w400, spacing: -0.08, color: subColor),
    labelLarge: s(size: 15, weight: FontWeight.w600, spacing: -0.24, color: AppleColors.systemBlue),
    labelMedium: s(size: 13, weight: FontWeight.w500, spacing: -0.08, color: subColor),
    labelSmall: s(size: 11, weight: FontWeight.w400, spacing: 0.07, color: subColor),
  );
}

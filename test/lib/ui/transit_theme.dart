import 'package:flutter/material.dart';

/// Design Tokens e Costanti Visive per il Transit Design System (v6.1.7).
/// Estratti e conformi alle specifiche in Transit_Design_System/.
class TransitColors {
  const TransitColors._();

  // Brand Primario
  static const brandGreen = Color(0xFF02B875);        // Transit Green (pulsante GO, tracciamento attivo)
  static const greenVibrant = Color(0xFF00C853);      // Live GPS pulse, onde radio satellitari
  static const darkBase = Color(0xFF010101);          // Nero profondo OLED (Dark Mode nativa, pin)
  static const white = Color(0xFFFEFEFE);             // Bianco puro riflettente per testi e bordi

  // Superfici
  static const surfaceDark1 = Color(0xFF1C1C1E);      // Schede primaria Dark Mode
  static const surfaceDark2 = Color(0xFF2C2C2E);      // Superficie secondaria Dark Mode
  static const surfaceLight1 = Color(0xFFFFFFFF);     // Schede primaria Light Mode
  static const surfaceLight2 = Color(0xFFF2F2F7);     // Sfondo grouped Light Mode

  // Stato del servizio (Service Health)
  static const statusGood = Color(0xFF34C759);        // Servizio regolare
  static const statusWarning = Color(0xFFFFA000);     // Allerta / Variazione orari
  static const statusDelay = Color(0xFFFF9500);       // Ritardo oltre 3 minuti
  static const statusDanger = Color(0xFFFF3B30);      // Fermata chiusa, linea deviata

  // Livelli di affollamento (Crowding)
  static const crowdingLow = Color(0xFF34C759);
  static const crowdingMedium = Color(0xFFFF9500);
  static const crowdingHigh = Color(0xFFFF3B30);
  static const crowdingUnknown = Color(0xFF8E8E93);

  // Transit Royale
  static const royalePurple = Color(0xFF6C3CE9);      // Viola primario Royale
  static const royalePurpleDark = Color(0xFF4D23B8);  // Gradiente secondario
  static const royaleGold = Color(0xFFFFC107);        // Oro corona VIP
  static const royaleGlow = Color(0x596C3CE9);        // Bagliore

  // Risoluzione dinamica superfici
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBase : surfaceLight2;
  }

  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? surfaceDark1 : surfaceLight1;
  }

  static Color secondarySurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? surfaceDark2 : surfaceLight2;
  }

  static Color label(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? white : darkBase;
  }

  static Color secondaryLabel(BuildContext context) {
    return const Color(0xFF8E8E93);
  }

  static Color tertiaryLabel(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0x7FFFFFFF)
        : const Color(0x66000000);
  }

  static Color separator(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0x33545458)
        : const Color(0x26000000);
  }

  /// Formula di calcolo contrasto testo GTFS (Transit Design System 01 §3):
  /// Luminanza L = 0.2126 * R + 0.7152 * G + 0.0722 * B
  /// Se contrasto con #FEFEFE >= 4.5:1 -> Bianco (#FEFEFE), altrimenti Nero (#010101).
  static Color contrastTextColor(Color background) {
    final l = background.computeLuminance();
    final contrastWhite = 1.05 / (l + 0.05);
    return contrastWhite >= 4.5 ? white : darkBase;
  }
}

/// Spaziature e dimensioni a griglia 4/8pt (Transit Design System 04).
class TransitSizes {
  const TransitSizes._();

  static const double spacingXxs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingBase = 16.0;
  static const double spacingLg = 20.0;
  static const double spacingXl = 24.0;
  static const double spacing2xl = 32.0;
  static const double spacing3xl = 48.0;

  // Squircle curvature
  static const double radiusBadgeSmall = 6.0;
  static const double radiusBadge = 8.0;
  static const double radiusCard = 16.0;
  static const double radiusBottomSheet = 24.0;
  static const double radiusPill = 9999.0;

  static const double minTappable = 44.0;
  static const double hairline = 0.5;

  // Elevazioni e ombre
  static const List<BoxShadow> elevationCard = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevationFab = [
    BoxShadow(
      color: Color(0x28000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}

/// Scala tipografica Transit (Puffin Transit Mobile hierarchy).
class TransitTypography {
  const TransitTypography._();

  /// Countdown display per minuti rimanenti: 38-44pt extra bold con cifre tabulari.
  static TextStyle countdownDisplay(BuildContext context, {Color? color}) => TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color ?? TransitColors.label(context),
      );

  static TextStyle countdownUnit(BuildContext context, {Color? color}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: color ?? TransitColors.secondaryLabel(context),
      );

  /// Sigla linea sui badge: 20-22pt bold.
  static TextStyle routeBadge(BuildContext context, {Color? color}) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: color ?? TransitColors.label(context),
      );

  /// Direzione / Capolinea primario: 17-18pt semibold.
  static TextStyle directionTitle(BuildContext context, {Color? color}) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color ?? TransitColors.label(context),
      );

  /// Nome fermata secondario: 15-16pt semibold/medium.
  static TextStyle stopName(BuildContext context, {Color? color}) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: color ?? TransitColors.label(context),
      );

  /// Frequenza / Metadati: 13-14pt regular.
  static TextStyle metadata(BuildContext context, {Color? color}) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: color ?? TransitColors.secondaryLabel(context),
      );

  /// Badge micro di stato (LIVE, GPS): 11-12pt extra bold all-caps.
  static TextStyle microBadge(BuildContext context, {Color? color}) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: color ?? TransitColors.brandGreen,
      );
}

/// Scheda squircle continua di Transit con supporto a barra di avviso laterale (AlertCell).
class TransitCard extends StatelessWidget {
  const TransitCard({
    required this.child,
    this.margin = const EdgeInsets.symmetric(
      horizontal: TransitSizes.spacingBase,
      vertical: 6,
    ),
    this.padding = const EdgeInsets.all(TransitSizes.spacingBase),
    this.onTap,
    this.backgroundColor,
    this.alertColor,
    this.alertBorderWidth = 4.0,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  /// Se fornito, aggiunge una barra laterale a sinistra di 4pt (Transit AlertCell pattern)
  final Color? alertColor;
  final double alertBorderWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? TransitColors.surfaceDark1 : TransitColors.surfaceLight1);

    Widget content = Container(
      decoration: BoxDecoration(
        color: bg,
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
              if (alertColor != null)
                Container(
                  width: alertBorderWidth,
                  color: alertColor,
                ),
              Expanded(
                child: Padding(
                  padding: padding,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      content = TransitBouncingButton(
        onTap: onTap,
        child: content,
      );
    }

    return Padding(
      padding: margin,
      child: content,
    );
  }
}

/// Pulsante con fisica a molla di rimbalzo (BounceButtonStyle - Transit 05 §3).
/// In pressione si riduce a 0.94 in 150ms, al rilascio rimbalza a 1.04 prima di tornare a 1.00.
class TransitBouncingButton extends StatefulWidget {
  const TransitBouncingButton({
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;

  @override
  State<TransitBouncingButton> createState() => _TransitBouncingButtonState();
}

class _TransitBouncingButtonState extends State<TransitBouncingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.94)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.04)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      _controller.forward(from: 0.0);
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      widget.onTap?.call();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Quando il controller non gira usiamo 1.0
          final scale = _controller.isAnimating ? _scaleAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Pillola di filtro modale (AnimatablePillStackView - Transit 05 §2).
/// Altezza 34pt, forma a capsula 9999pt, attiva in Transit Green #02B875.
class TransitFilterPill extends StatelessWidget {
  const TransitFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = selected
        ? TransitColors.brandGreen
        : (isDark ? const Color(0x26FFFFFF) : const Color(0x12000000));

    final textColor = selected
        ? TransitColors.white
        : TransitColors.label(context);

    return TransitBouncingButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(TransitSizes.radiusPill),
          border: selected
              ? null
              : Border.all(
                  color: isDark ? const Color(0x26FFFFFF) : const Color(0x1A000000),
                  width: 0.5,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark ? const Color(0x33FFFFFF) : const Color(0x22000000)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Indicatore di onde radio / radar live pulsante (Transit 05 §1).
class TransitLiveWaveIcon extends StatefulWidget {
  const TransitLiveWaveIcon({
    this.color = TransitColors.greenVibrant,
    this.size = 16,
    super.key,
  });

  final Color color;
  final double size;

  @override
  State<TransitLiveWaveIcon> createState() => _TransitLiveWaveIconState();
}

class _TransitLiveWaveIconState extends State<TransitLiveWaveIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final opacity = 0.55 + (_pulseController.value * 0.45);
        return Opacity(
          opacity: opacity,
          child: Icon(
            Icons.wifi_tethering,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'transit_theme.dart';

/// Adapter per la palette colori del Transit Design System.
/// Mappa i token semantici sui valori ufficiali di Transit (v6.1.7).
class AppleColors {
  const AppleColors._();

  static const systemBlue = TransitColors.brandGreen;        // Transit Green primario
  static const systemGreen = TransitColors.statusGood;       // Transit Status Good (#34C759)
  static const systemOrange = TransitColors.statusWarning;   // Transit Status Warning (#FFA000)
  static const systemRed = TransitColors.statusDanger;       // Transit Status Danger (#FF3B30)
  static const systemPurple = TransitColors.royalePurple;    // Transit Royale Purple (#6C3CE9)
  static const systemIndigo = TransitColors.royalePurpleDark;
  static const systemTeal = TransitColors.greenVibrant;      // Live pulse (#00C853)
  static const systemYellow = TransitColors.royaleGold;      // Royale Gold (#FFC107)
  static const systemGray = Color(0xFF8E8E93);

  // Sfondi grouped e superfici Transit
  static Color systemGroupedBackground(BuildContext context) {
    return TransitColors.background(context);
  }

  static Color secondarySystemGroupedBackground(BuildContext context) {
    return TransitColors.cardBackground(context);
  }

  static Color tertiarySystemGroupedBackground(BuildContext context) {
    return TransitColors.secondarySurface(context);
  }

  // Sfondi standard
  static Color systemBackground(BuildContext context) {
    return TransitColors.background(context);
  }

  static Color secondarySystemBackground(BuildContext context) {
    return TransitColors.secondarySurface(context);
  }

  // Testo
  static Color label(BuildContext context) {
    return TransitColors.label(context);
  }

  static Color secondaryLabel(BuildContext context) {
    return TransitColors.secondaryLabel(context);
  }

  static Color tertiaryLabel(BuildContext context) {
    return TransitColors.tertiaryLabel(context);
  }

  // Separatori
  static Color separator(BuildContext context) {
    return TransitColors.separator(context);
  }

  static Color opaqueSeparator(BuildContext context) {
    return TransitColors.separator(context);
  }
}

/// Scala tipografica Transit/HIG.
class AppleTypography {
  const AppleTypography._();

  static TextStyle largeTitle(BuildContext context) => TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppleColors.label(context),
      );

  static TextStyle title1(BuildContext context) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppleColors.label(context),
      );

  static TextStyle title2(BuildContext context) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppleColors.label(context),
      );

  static TextStyle title3(BuildContext context) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppleColors.label(context),
      );

  static TextStyle headline(BuildContext context) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppleColors.label(context),
      );

  static TextStyle body(BuildContext context) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        color: AppleColors.label(context),
      );

  static TextStyle callout(BuildContext context) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: AppleColors.label(context),
      );

  static TextStyle subheadline(BuildContext context) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppleColors.secondaryLabel(context),
      );

  static TextStyle footnote(BuildContext context) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: AppleColors.secondaryLabel(context),
      );

  static TextStyle caption1(BuildContext context) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: AppleColors.secondaryLabel(context),
      );

  static TextStyle caption2(BuildContext context) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppleColors.secondaryLabel(context),
      );

  static TextStyle sectionHeader(BuildContext context) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppleColors.secondaryLabel(context),
      );
}

/// Misure e raggi Transit (Transit Design System 04).
class AppleSizes {
  const AppleSizes._();

  static const double radiusCard = TransitSizes.radiusCard;       // 16.0
  static const double radiusPill = TransitSizes.radiusPill;       // 9999.0
  static const double radiusSmall = TransitSizes.radiusBadgeSmall;// 6.0
  static const double radiusSm = TransitSizes.radiusBadge;        // 8.0
  static const double radiusMd = 12.0;
  static const double radiusLg = TransitSizes.radiusCard;         // 16.0
  static const double hairline = TransitSizes.hairline;           // 0.5
  static const double marginHorizontal = TransitSizes.spacingBase;// 16.0
  static const double minTappable = TransitSizes.minTappable;     // 44.0
}

/// Card raggruppata continua in squircle 16pt secondo Transit Design System.
class AppGroupedCard extends StatelessWidget {
  const AppGroupedCard({
    required this.child,
    this.margin = const EdgeInsets.symmetric(
      horizontal: AppleSizes.marginHorizontal,
      vertical: 6,
    ),
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? AppleColors.secondarySystemGroupedBackground(context);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppleSizes.radiusCard),
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
      child: child,
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

/// Sezione con intestazione discreta in maiuscolo e raggruppamento card Transit.
class AppSection extends StatelessWidget {
  const AppSection({
    required this.children,
    this.header,
    this.footer,
    this.margin = const EdgeInsets.fromLTRB(16, 16, 16, 6),
    super.key,
  });

  final String? header;
  final String? footer;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headerWidget = header != null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              header!.toUpperCase(),
              style: AppleTypography.sectionHeader(context),
            ),
          )
        : null;

    final footerWidget = footer != null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              footer!,
              style: AppleTypography.footnote(context),
            ),
          )
        : null;

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?headerWidget,
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppleColors.secondarySystemGroupedBackground(context),
              borderRadius: BorderRadius.circular(AppleSizes.radiusCard),
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
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Divider(
                        height: AppleSizes.hairline,
                        thickness: AppleSizes.hairline,
                        color: AppleColors.separator(context),
                      ),
                    ),
                ],
              ],
            ),
          ),
          ?footerWidget,
        ],
      ),
    );
  }
}

/// Riga interattiva Transit.
class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.minHeight = AppleSizes.minTappable,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  title,
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    subtitle!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: AppleColors.secondaryLabel(context),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: AppleColors.separator(context),
        child: content,
      );
    }

    return content;
  }
}

/// Badge a pillola per lo stato secondo Transit (Transit 05 §2).
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.text,
    required this.color,
    this.icon,
    this.outline = false,
    super.key,
  });

  const StatusPill.alert(
    this.text, {
    this.icon,
    this.outline = false,
    super.key,
  }) : color = TransitColors.statusDanger;

  const StatusPill.success(
    this.text, {
    this.icon,
    this.outline = false,
    super.key,
  }) : color = TransitColors.statusGood;

  const StatusPill.info(
    this.text, {
    this.icon,
    this.outline = false,
    super.key,
  }) : color = TransitColors.brandGreen;

  const StatusPill.warning(
    this.text, {
    this.icon,
    this.outline = false,
    super.key,
  }) : color = TransitColors.statusWarning;

  final String text;
  final Color color;
  final IconData? icon;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: outline ? Colors.transparent : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(TransitSizes.radiusPill),
        border: outline ? Border.all(color: color, width: 1.0) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra o header traslucido con sfocatura frosted glass stile iOS.
class AppleTranslucentBar extends StatelessWidget {
  const AppleTranslucentBar({
    required this.child,
    this.blur = 20.0,
    this.borderBottom = true,
    super.key,
  });

  final Widget child;
  final double blur;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? const Color(0xCC010101)
        : const Color(0xCCFFFFFF);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: borderBottom
                ? Border(
                    bottom: BorderSide(
                      color: AppleColors.separator(context),
                      width: AppleSizes.hairline,
                    ),
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

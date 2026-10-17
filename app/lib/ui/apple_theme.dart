import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Palette dei colori Apple ispirata alle Human Interface Guidelines (HIG).
class AppleColors {
  const AppleColors._();

  static const systemBlue = Color(0xFF007AFF);
  static const systemGreen = Color(0xFF34C759);
  static const systemOrange = Color(0xFFFF9500);
  static const systemRed = Color(0xFFFF3B30);
  static const systemPurple = Color(0xFFAF52DE);
  static const systemIndigo = Color(0xFF5856D6);
  static const systemTeal = Color(0xFF30B0C7);
  static const systemYellow = Color(0xFFFFCC00);
  static const systemGray = Color(0xFF8E8E93);

  // Sfondi grouped (stile Impostazioni / Liste iOS)
  static Color systemGroupedBackground(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      CupertinoColors.systemGroupedBackground,
      context,
    );
  }

  static Color secondarySystemGroupedBackground(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      CupertinoColors.secondarySystemGroupedBackground,
      context,
    );
  }

  static Color tertiarySystemGroupedBackground(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      CupertinoColors.tertiarySystemGroupedBackground,
      context,
    );
  }

  // Sfondi standard
  static Color systemBackground(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      CupertinoColors.systemBackground,
      context,
    );
  }

  static Color secondarySystemBackground(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      CupertinoColors.secondarySystemBackground,
      context,
    );
  }

  // Testo
  static Color label(BuildContext context) {
    return CupertinoDynamicColor.resolve(CupertinoColors.label, context);
  }

  static Color secondaryLabel(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      CupertinoColors.secondaryLabel,
      context,
    );
  }

  static Color tertiaryLabel(BuildContext context) {
    return CupertinoDynamicColor.resolve(CupertinoColors.tertiaryLabel, context);
  }

  // Separatori
  static Color separator(BuildContext context) {
    return CupertinoDynamicColor.resolve(CupertinoColors.separator, context);
  }

  static Color opaqueSeparator(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      CupertinoColors.opaqueSeparator,
      context,
    );
  }
}

/// Scala tipografica iOS (San Francisco).
class AppleTypography {
  const AppleTypography._();

  static TextStyle largeTitle(BuildContext context) => TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.37,
        color: AppleColors.label(context),
      );

  static TextStyle title1(BuildContext context) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.36,
        color: AppleColors.label(context),
      );

  static TextStyle title2(BuildContext context) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.35,
        color: AppleColors.label(context),
      );

  static TextStyle title3(BuildContext context) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.38,
        color: AppleColors.label(context),
      );

  static TextStyle headline(BuildContext context) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
        color: AppleColors.label(context),
      );

  static TextStyle body(BuildContext context) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.41,
        color: AppleColors.label(context),
      );

  static TextStyle callout(BuildContext context) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.32,
        color: AppleColors.label(context),
      );

  static TextStyle subheadline(BuildContext context) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.24,
        color: AppleColors.secondaryLabel(context),
      );

  static TextStyle footnote(BuildContext context) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.08,
        color: AppleColors.secondaryLabel(context),
      );

  static TextStyle caption1(BuildContext context) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppleColors.secondaryLabel(context),
      );

  static TextStyle caption2(BuildContext context) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.07,
        color: AppleColors.secondaryLabel(context),
      );

  static TextStyle sectionHeader(BuildContext context) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.08,
        color: AppleColors.secondaryLabel(context),
      );
}

/// Misure e raggi Apple HIG.
class AppleSizes {
  const AppleSizes._();

  static const double radiusCard = 12.0;
  static const double radiusPill = 20.0;
  static const double radiusSmall = 6.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 16.0;
  static const double hairline = 0.5;
  static const double marginHorizontal = 16.0;
  static const double minTappable = 44.0;
}

/// Card raggruppata continua in stile iOS Inset Grouped.
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
    final bg = color ?? AppleColors.secondarySystemGroupedBackground(context);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppleSizes.radiusCard),
      ),
      child: child,
    );

    if (onTap != null) {
      content = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        pressedOpacity: 0.7,
        child: content,
      );
    }

    return Padding(
      padding: margin,
      child: content,
    );
  }
}

/// Sezione con intestazione discreta in maiuscolo/grigio stile iOS Settings.
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
    final headerWidget = header != null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              header!.toUpperCase(),
              style: AppleTypography.sectionHeader(context),
            ),
          )
        : null;

    final footerWidget = footer != null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
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

/// Riga interattiva in stile iOS ListTile.
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

/// Badge discreto a pillola per lo stato (Regolare, Deviata, Sciopero, Live).
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
  }) : color = AppleColors.systemRed;

  const StatusPill.success(
    this.text, {
    this.icon,
    this.outline = false,
    super.key,
  }) : color = AppleColors.systemGreen;

  const StatusPill.info(
    this.text, {
    this.icon,
    this.outline = false,
    super.key,
  }) : color = AppleColors.systemBlue;

  const StatusPill.warning(
    this.text, {
    this.icon,
    this.outline = false,
    super.key,
  }) : color = AppleColors.systemOrange;

  final String text;
  final Color color;
  final IconData? icon;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outline ? Colors.transparent : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppleSizes.radiusPill),
        border: outline ? Border.all(color: color, width: AppleSizes.hairline) : null,
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
              fontWeight: FontWeight.w600,
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
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final bg = isDark
        ? const Color(0xCC1C1C1E)
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

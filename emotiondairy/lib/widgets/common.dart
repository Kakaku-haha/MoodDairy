import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color = AppColors.surface,
    this.gradient,
    this.borderColor = AppColors.line,
    this.radius = 26,
    this.onTap,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final Gradient? gradient;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow ? AppShadows.soft : null,
      ),
      child: child,
    );

    final wrapped = margin == null
        ? content
        : Padding(padding: margin!, child: content);

    if (onTap == null) return wrapped;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: AppColors.primarySoft.withValues(alpha: 0.5),
        highlightColor: Colors.transparent,
        child: wrapped,
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '暖',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.46,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          Positioned(
            right: size * 0.18,
            top: size * 0.17,
            child: Container(
              width: size * 0.12,
              height: size * 0.12,
              decoration: const BoxDecoration(
                color: AppColors.apricot,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(size: 40),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '暖迹',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: compact ? 18 : 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            if (!compact)
              Text(
                '把心情，轻轻留下',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing case final Widget trailing) trailing,
        ],
      ),
    );
  }
}

class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.surfaceWarm,
    this.textColor = AppColors.inkSoft,
    this.borderColor = Colors.transparent,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.28)
              : Colors.transparent,
        ),
      ),
      child: Text(
        '# $label',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: selected ? AppColors.primaryDeep : AppColors.muted,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor = AppColors.surface,
    this.iconColor = AppColors.inkSoft,
    this.size = 42,
    this.border = true,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size * 0.36),
        side: BorderSide(color: border ? AppColors.line : Colors.transparent),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size * 0.36),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.47, color: iconColor),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.spa_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWarm,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.peach, size: 25),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

void showWarmSnackBar(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_outline_rounded,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 2200),
        content: Row(
          children: [
            Icon(icon, color: AppColors.apricot, size: 19),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required String body,
  String buttonLabel = '知道了',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonLabel),
        ),
      ],
    ),
  );
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toneup_app/components/feedback_button.dart';

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color? color;

  /// 最精简的骨架屏圆角矩形
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? Colors.grey[300],
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class LoadingOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// 显示加载浮层
  static void show(BuildContext context) {
    if (_isShowing) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_overlayEntry != null) return;
      ThemeData theme = Theme.of(context);
      _overlayEntry = OverlayEntry(
        builder: (context) => Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(color: theme.colorScheme.scrim.withAlpha(20)),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      strokeCap: StrokeCap.round,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'loading...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
      _isShowing = true;
    });
  }

  // 隐藏加载浮层
  static void hide() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowing = false;
    });
  }
}

/// 主操作按钮
Widget mainActionButton({
  required BuildContext context,
  required String label,
  VoidCallback? onTap,
  IconData? icon,
  IconAlignment? iconAlignment,
  bool isLoading = false,
  double radius = 16,
  Color? backColor,
  Color? frontColor,
  Color borderColor = Colors.transparent,
  String? loadingLabel,
  MainAxisSize mainAxisSize = MainAxisSize.max,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  ),
}) {
  final theme = Theme.of(context);
  final isFixed = (onTap == null || isLoading);
  backColor = (onTap == null || isLoading == true)
      ? theme.colorScheme.outlineVariant.withAlpha(80)
      : backColor ?? theme.colorScheme.primary;
  frontColor = (onTap == null || isLoading == true)
      ? theme.colorScheme.outline
      : frontColor ?? theme.colorScheme.onPrimary;

  return Material(
    color: Colors.transparent,
    child: FeedbackButton(
      borderRadius: BorderRadius.circular(16),
      onTap: isFixed
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onTap();
            },
      child: Ink(
        padding: padding,
        decoration: ShapeDecoration(
          color: backColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
              color: borderColor,
            ),
          ),
        ),
        child: loadingLabel == null
            ? Row(
                mainAxisSize: mainAxisSize,
                mainAxisAlignment: (iconAlignment != null)
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                spacing: 12,
                children: [
                  if (icon != null && iconAlignment == IconAlignment.end)
                    SizedBox(width: 24),
                  if (icon != null && iconAlignment == IconAlignment.start)
                    Icon(icon, color: frontColor),
                  if (icon != null && iconAlignment == null)
                    Icon(icon, color: frontColor),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: frontColor,
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (icon != null && iconAlignment == IconAlignment.end)
                    Icon(icon, color: frontColor),
                  if (icon != null && iconAlignment == IconAlignment.start)
                    SizedBox(width: 24),
                ],
              )
            : Row(
                mainAxisSize: mainAxisSize,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loadingLabel,
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: frontColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

Widget tagLabel({
  required BuildContext context,
  required String label,
  Color? backColor,
  Color? frontColor,
  EdgeInsetsGeometry? padding,
  double? fontSize,
}) {
  final theme = Theme.of(context);
  return Container(
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: ShapeDecoration(
      color: backColor ?? theme.colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          width: 1,
          strokeAlign: BorderSide.strokeAlignCenter,
          color:
              (frontColor ?? Theme.of(context).colorScheme.onSecondaryContainer)
                  .withAlpha(40),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    child: Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: frontColor ?? Theme.of(context).colorScheme.onSecondaryContainer,
        fontSize: fontSize,
      ),
    ),
  );
}

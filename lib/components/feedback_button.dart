import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 带缩放和水波纹效果的反馈按钮组件
class FeedbackButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enableFeedback; // 是否启用系统触感反馈
  final Color? splashColor; // 水波纹颜色
  final Color? highlightColor; // 高亮颜色
  final BorderRadius? borderRadius; // 水波纹圆角
  final double scaleFactor; // 缩放比例，默认0.9（交互时的缩放值）

  const FeedbackButton({
    super.key,
    required this.child,
    this.onTap,
    this.enableFeedback = true,
    this.splashColor,
    this.highlightColor,
    this.borderRadius,
    this.scaleFactor = 0.9, // 修改注释说明，明确是交互时的缩放值
  });

  @override
  State<FeedbackButton> createState() => _FeedbackButtonState();
}

class _FeedbackButtonState extends State<FeedbackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器 - 调整上下界，默认状态为1，交互时缩小到scaleFactor
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: widget.scaleFactor, // 交互时的最小缩放值
      upperBound: 1, // 默认状态的缩放值
      value: 1, // 初始值设为1（默认不缩放）
    );

    // 缩放动画
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 处理触摸按下 - 按下时缩小
  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.reverse(); // 从1缩放到scaleFactor
      if (widget.enableFeedback) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  // 处理触摸抬起 - 抬起时恢复
  void _handleTapUp(TapUpDetails details) {
    _controller.forward(); // 从scaleFactor恢复到1
    _handleTap(context);
  }

  // 处理触摸取消 - 取消时恢复
  void _handleTapCancel() {
    _controller.forward(); // 从scaleFactor恢复到1
  }

  // 统一处理点击反馈
  void _handleTap(BuildContext context) {
    // 1. 系统触感反馈（震动）
    // if (widget.enableFeedback) {
    //   HapticFeedback.lightImpact();
    // }
    // 2. 执行实际点击逻辑
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: InkWell(
            onTapDown: widget.onTap != null ? _handleTapDown : null,
            onTapUp: widget.onTap != null ? _handleTapUp : null,
            onTapCancel: widget.onTap != null ? _handleTapCancel : null,
            onTap: null, // 禁用原有onTap，使用自定义触摸事件
            splashColor:
                widget.splashColor ??
                Theme.of(context).colorScheme.primary.withAlpha(50),
            highlightColor:
                widget.highlightColor ??
                Theme.of(context).colorScheme.primary.withAlpha(10),
            enableFeedback: widget.enableFeedback,
            borderRadius: widget.borderRadius,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';

class WaveAnimation extends StatefulWidget {
  final bool isPlaying;
  final bool isLoading;
  final Size size;
  final int barWidth;
  final Color color;
  final Color highlight;
  final Color idle;
  const WaveAnimation({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.color,
    required this.highlight,
    required this.idle,
    Size? size,
    int? barWidth,
  }) : size = size ?? const Size(60, 24),
       barWidth = barWidth ?? 2;

  @override
  State<WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPlaying || widget.isLoading) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
    final columns = (widget.size.width / (widget.barWidth * 2)).floor();
    final maxHeight = widget.size.height;
    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(columns, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final loadingPhase = sin(_controller.value * 2 * pi);
              final noise =
                  sin((_controller.value * 10 * pi) + i) * 0.2 +
                  Random().nextDouble() * 0.1;
              final loadingWave1 = //左右滑动
                  maxHeight *
                  (0.1 +
                      0.3 *
                          (0.2 +
                              0.2 *
                                  sin(
                                    (i / columns * pi * 2) + loadingPhase * pi,
                                  )));
              // ignore: unused_local_variable
              final loadingWave2 = //快速闪动
                  maxHeight *
                  (0.2 +
                      0.6 *
                          (0.5 +
                              0.5 *
                                  sin((_controller.value * 4 * pi) + (i % 4))));
              final playingWave1 = //波形滑动
                  maxHeight *
                  (0.1 +
                      0.9 *
                          ((columns / 2 - (i - columns / 2).abs()) /
                              (columns / 2)) *
                          (0.5 +
                              0.5 *
                                  sin(
                                    (_controller.value * 4 * pi) -
                                        (i * pi / 16),
                                  )));
              // ignore: unused_local_variable
              final playingWave2 = //随机震荡
                  maxHeight *
                  (0.2 +
                      0.7 *
                          ((columns / 2 - (i - columns / 2).abs()) /
                              (columns / 2)) *
                          (0.5 +
                              0.5 *
                                  sin(
                                    (_controller.value * 6 * pi) - (i * pi / 1),
                                  ) +
                              noise));

              final height = widget.isLoading ? loadingWave1 : playingWave1;
              return Container(
                width: widget.barWidth.toDouble(),
                height: height,
                decoration: BoxDecoration(
                  //  color; highlight; idle;
                  color: widget.isLoading
                      ? widget.idle
                      : widget.isPlaying
                      ? widget.highlight
                      : widget.color,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

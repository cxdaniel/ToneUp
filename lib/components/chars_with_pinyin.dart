import 'package:flutter/material.dart';

class CharsWithPinyin extends StatefulWidget {
  final String? pinyin;
  final String chinese;
  final double? size;

  const CharsWithPinyin({
    super.key,
    required this.chinese,
    this.pinyin,
    this.size,
  });

  @override
  State<CharsWithPinyin> createState() => _CharsWithPinyinState();
}

class _CharsWithPinyinState extends State<CharsWithPinyin> {
  @override
  Widget build(BuildContext context) {
    final fontsize = (widget.size != null) ? widget.size : 36.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.pinyin != null)
          Text(
            widget.pinyin!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontSize: fontsize! * 0.5,
            ),
          ),
        Text(
          widget.chinese,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            fontSize: fontsize,
          ),
        ),
      ],
    );
  }
}

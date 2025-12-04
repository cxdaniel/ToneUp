import 'package:flutter/material.dart';
import 'package:pinyin/pinyin.dart';
import 'package:toneup_app/services/utils.dart';

class CharsWithPinyin extends StatefulWidget {
  final String chinese;
  final bool showPinyin;
  final double size;

  const CharsWithPinyin({
    super.key,
    required this.chinese,
    this.showPinyin = true,
    this.size = 36,
  });

  @override
  State<CharsWithPinyin> createState() => _CharsWithPinyinState();
}

class _CharsWithPinyinState extends State<CharsWithPinyin> {
  @override
  Widget build(BuildContext context) {
    final pinyin = AppUtils.isChinese(widget.chinese)
        ? PinyinHelper.getPinyin(
            widget.chinese,
            format: PinyinFormat.WITH_TONE_MARK,
          )
        : '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.showPinyin)
          Text(
            pinyin,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              height: 1,
              fontSize: widget.size * .5,
            ),
          ),
        Text(
          widget.chinese,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            height: 1.2,
            fontSize: widget.size,
          ),
        ),
      ],
    );
  }
}

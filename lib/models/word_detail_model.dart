/// 词语详情模型
/// 用于显示词典面板的词条信息
class WordDetailModel {
  final String word; // 汉字词语
  final String pinyin; // 拼音
  final String? translation; // 英文翻译
  final String? exampleSentence; // 例句（当前句子上下文）

  WordDetailModel({
    required this.word,
    required this.pinyin,
    this.translation,
    this.exampleSentence,
  });
}

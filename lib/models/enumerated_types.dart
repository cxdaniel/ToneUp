import 'package:json_annotation/json_annotation.dart';

/// 用户计划状态枚举
enum PlanStatus {
  active,
  pending,
  done,
  reactive;

  String get name => _$PlanStatusEnumMap[this]!;
}

/// 练习模板类型
enum QuizTemplate {
  @JsonValue('看文选文')
  textToText,
  @JsonValue('看文选音')
  textToVoice,
  @JsonValue('听音选文')
  voiceToText,
  @JsonValue('左右配对')
  leftToRight,
  @JsonValue('多项填多空')
  multiToMulti,
  @JsonValue('连词成句')
  orderAndJoin,
  @JsonValue('复述例句')
  recordOfExample,
  @JsonValue('描红写字')
  tracOfExample,
  @JsonValue('键盘输入')
  typeOfText;

  String get name => _$QuizTemplateEnumMap[this]!;
}

/// 题型枚举（匹配表中的 quiz_type 类型）
enum QuizType {
  @JsonValue('选择题')
  choice,
  @JsonValue('配对题')
  matching,
  @JsonValue('选择填空')
  cloze,
  @JsonValue('选词拼句')
  sorted,
  @JsonValue('复述录音')
  recoding,
  @JsonValue('汉字描红')
  tracing,
  @JsonValue('文本输入')
  typing;

  String get name => _$QuizTypeEnumMap[this]!;
}

/// 素材类型枚举（匹配 material_type 数组）
enum MaterialType {
  @JsonValue('character')
  character,
  @JsonValue('word')
  word,
  @JsonValue('sentence')
  sentence,
  @JsonValue('dialog')
  dialog,
  @JsonValue('paragraph')
  paragraph,
  @JsonValue('syllable')
  syllable,
  @JsonValue('grammar')
  grammar;

  String get name => _$MaterialTypeEnumMap[this]!;
}

/// 指标类别枚举（匹配 indicator_cats 数组）
enum IndicatorCategory {
  @JsonValue('辨认汉字')
  charsRecognition,
  @JsonValue('辨认词汇')
  wordRecognition,
  @JsonValue('掌握语法')
  grammar,
  @JsonValue('听懂句子')
  listening,
  @JsonValue('听力速度')
  listeningSpeed,
  @JsonValue('掌握音节')
  syllable,
  @JsonValue('口语表达')
  expression,
  @JsonValue('文本理解')
  comprehension,
  @JsonValue('阅读速度')
  readingSpeed,
  @JsonValue('阅读技能')
  readingSkill,
  @JsonValue('抄写速度')
  typingSpeed,
  @JsonValue('汉字书写')
  writing,
  @JsonValue('书写规范')
  writingNorms,
  @JsonValue('书面写作')
  writtenWriting,
  @JsonValue('文本翻译')
  translation;

  String get name => _$IndicatorCategoryEnumMap[this]!;
}

/// 语言技能组枚举（匹配 skill_groups 数组）
enum SkillGroup {
  @JsonValue('认')
  recognition,
  @JsonValue('听')
  listening,
  @JsonValue('说')
  speaking,
  @JsonValue('读')
  reading,
  @JsonValue('写')
  writing,
  @JsonValue('译')
  translation,
}

const _$QuizTemplateEnumMap = {
  QuizTemplate.textToText: '看文选文',
  QuizTemplate.textToVoice: '看文选音',
  QuizTemplate.voiceToText: '听音选文',
  QuizTemplate.leftToRight: '左右配对',
  QuizTemplate.multiToMulti: '多项填多空',
  QuizTemplate.orderAndJoin: '连词成句',
  QuizTemplate.recordOfExample: '复述例句',
  QuizTemplate.tracOfExample: '描红写字',
  QuizTemplate.typeOfText: '键盘输入',
};

/// 枚举映射
const _$PlanStatusEnumMap = {
  PlanStatus.active: 'active',
  PlanStatus.pending: 'pending',
  PlanStatus.done: 'done',
  PlanStatus.reactive: 'reactive',
};
const _$QuizTypeEnumMap = {
  QuizType.choice: '选择题',
  QuizType.matching: '配对题',
  QuizType.cloze: '选择填空',
  QuizType.sorted: '选词拼句',
  QuizType.recoding: '复述录音',
  QuizType.tracing: '汉字描红',
  QuizType.typing: '文本输入',
};

const _$MaterialTypeEnumMap = {
  MaterialType.character: 'character',
  MaterialType.word: 'word',
  MaterialType.sentence: 'sentence',
  MaterialType.dialog: 'dialog',
  MaterialType.paragraph: 'paragraph',
  MaterialType.syllable: 'syllable',
  MaterialType.grammar: 'grammar',
};

const _$IndicatorCategoryEnumMap = {
  IndicatorCategory.charsRecognition: '辨认汉字',
  IndicatorCategory.wordRecognition: '辨认词汇',
  IndicatorCategory.grammar: '掌握语法',
  IndicatorCategory.listening: '听懂句子',
  IndicatorCategory.listeningSpeed: '听力速度',
  IndicatorCategory.syllable: '掌握音节',
  IndicatorCategory.expression: '口语表达',
  IndicatorCategory.comprehension: '文本理解',
  IndicatorCategory.readingSpeed: '阅读速度',
  IndicatorCategory.readingSkill: '阅读技能',
  IndicatorCategory.typingSpeed: '抄写速度',
  IndicatorCategory.writing: '汉字书写',
  IndicatorCategory.writingNorms: '书写规范',
  IndicatorCategory.writtenWriting: '书面写作',
  IndicatorCategory.translation: '文本翻译',
};

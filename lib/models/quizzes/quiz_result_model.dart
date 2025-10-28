import 'package:toneup_app/models/enumerated_types.dart';

class QuizResultModel {
  double score;
  final MaterialContentType category;
  final String item;
  int? itemId;

  QuizResultModel({
    required this.score,
    required this.category,
    required this.item,
    this.itemId,
  });
}

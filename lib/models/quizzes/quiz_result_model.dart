import 'package:toneup_app/models/enumerated_types.dart';

class QuizResultModel {
  double score;
  MaterialContentType? category;
  String? item;
  int? itemId;

  QuizResultModel({required this.score, this.category, this.item, this.itemId});
}

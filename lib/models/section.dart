import 'question.dart';

class Section {
  final String name;
  final List<Question> questions;

  Section({required this.name, required this.questions});

  factory Section.fromJson(Map<String, dynamic> json) {
    final questionsData = json['questions'];
    final questionsList = <Question>[];

    if (questionsData != null) {
      if (questionsData is List) {
        // Web-friendly
        for (var q in questionsData) {
          questionsList.add(
            Question.fromJson(
              Map<String, dynamic>.from(q as Map),
              questionsData.indexOf(q),
            ),
          );
        }
      } else if (questionsData is Map) {
        // Mobile / standard
        for (var q in questionsData.values) {
          questionsList.add(
            Question.fromJson(
              Map<String, dynamic>.from(q as Map),
              questionsData.values.toList().indexOf(q),
            ),
          );
        }
      }
    }

    return Section(name: json['name'], questions: questionsList);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'questions': questions.map((q) => q.toJson()).toList(),
  };
}

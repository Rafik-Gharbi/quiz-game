import 'section.dart';

class QuizData {
  final List<Section> sections;

  QuizData({required this.sections});

  factory QuizData.fromJson(Map<String, dynamic> json) {
    final sectionsData = json['sections'];
    final sectionsList = <Section>[];

    if (sectionsData != null) {
      if (sectionsData is List) {
        // Web-friendly
        for (var s in sectionsData) {
          sectionsList.add(
            Section.fromJson(Map<String, dynamic>.from(s as Map)),
          );
        }
      } else if (sectionsData is Map) {
        // Mobile / standard
        for (var s in sectionsData.values) {
          sectionsList.add(
            Section.fromJson(Map<String, dynamic>.from(s as Map)),
          );
        }
      }
    }

    return QuizData(sections: sectionsList);
  }

  Map<String, dynamic> toJson() => {
    'sections': sections.map((s) => s.toJson()).toList(),
  };
}

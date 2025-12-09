class Question {
  final String question;
  final String type; // 'single' or 'multiple'
  final List<Answer> options;
  final List<int> correct;
  final int timeLimit;

  Question({
    required this.question,
    required this.type,
    required this.options,
    required this.correct,
    required this.timeLimit,
  });

  factory Question.fromJson(Map<String, dynamic> json, int index) {
    List<Answer> answers = [];
    final options = json['options'] ?? [];
    for (var o in options) {
      answers.add(Answer.fromJson(o, options.indexOf(o)));
    }
    return Question(
      question: json['question'],
      type: json['type'],
      options: answers,
      correct: List<int>.from(json['correct']),
      timeLimit: json['timeLimit'],
    );
  }

  Map<String, dynamic> toJson() {
    final options = List.of(this.options)..sort((a, b) => a.index.compareTo(b.index));
    return {
    'question': question,
    'type': type,
    'options': options.map((o) => o.text).toList(),
    'correct': correct,
    'timeLimit': timeLimit,
  };
  }
}

class Answer {
  final String text;
  final int index;

  Answer({required this.text, required this.index});

  factory Answer.fromJson(String text, int index) {
    return Answer(text: text, index: index);
  }

  Map<String, dynamic> toJson() => {'text': text, 'index': index};
}

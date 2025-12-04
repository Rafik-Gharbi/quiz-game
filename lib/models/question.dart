class Question {
  final String question;
  final String type; // 'single' or 'multiple'
  final List<String> options;
  final List<int> correct;
  final int timeLimit;

  Question({
    required this.question,
    required this.type,
    required this.options,
    required this.correct,
    required this.timeLimit,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'],
      type: json['type'],
      options: List<String>.from(json['options']),
      correct: List<int>.from(json['correct']),
      timeLimit: json['timeLimit'],
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'type': type,
    'options': options,
    'correct': correct,
    'timeLimit': timeLimit,
  };
}

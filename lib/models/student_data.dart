import 'package:quiz_games/models/student.dart';

import '../utils/helper.dart';

class StudentData {
  final Student student;
  final Map<String, dynamic> answers;
  final int currentQuestionIndex;
  final int currentSectionIndex;
  final String finishedAt;
  final String joinedAt;
  final int score;
  final String status; // waiting, finished

  StudentData({
    required this.student,
    required this.answers,
    required this.currentQuestionIndex,
    required this.currentSectionIndex,
    required this.finishedAt,
    required this.joinedAt,
    required this.score,
    required this.status,
  });

  factory StudentData.fromJson(Map<String, dynamic> json) {
    return StudentData(
      student: Student(
        uid: json['uid'] ?? json['id'],
        name: json['name'],
        joinedAt: Helper.joinedTime(json['joinedAt']),
      ),
      answers: Map<String, dynamic>.from(json['answers'] as Map? ?? {}),
      currentQuestionIndex: json['currentQuestionIndex'],
      currentSectionIndex: json['currentSectionIndex'],
      joinedAt: Helper.joinedTime(json['joinedAt']),
      finishedAt: Helper.joinedTime(json['finishedAt']),
      score: json['score'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'student': student.toJson(),
    'answers': answers,
    'currentQuestionIndex': currentQuestionIndex,
    'currentSectionIndex': currentSectionIndex,
    'joinedAt': joinedAt,
    'finishedAt': finishedAt,
    'score': score,
    'status': status,
  };
}

import 'package:quiz_games/models/student.dart';

import '../utils/helper.dart';

class StudentData {
  final Student student;
  final Map<String, dynamic> answers;
  final Map<int, String?> cheated;
  final int currentQuestionIndex;
  final int currentSectionIndex;
  final String? finishedAt;
  final String joinedAt;
  final int score;
  String status; // waiting, active, finished

  StudentData({
    required this.student,
    required this.answers,
    required this.cheated,
    required this.currentQuestionIndex,
    required this.currentSectionIndex,
    required this.finishedAt,
    required this.joinedAt,
    required this.score,
    required this.status,
  });

  factory StudentData.fromJson(Map<String, dynamic> json) {
    final cheatedRaw = json['cheated'];

    Map<int, String> cheatedMap = {};

    if (cheatedRaw is Map) {
      // Proper map representation
      cheatedRaw.forEach((key, value) {
        final intKey = int.tryParse(key.toString());
        if (intKey != null && value != null) {
          cheatedMap[intKey] = value.toString();
        }
      });
    } else if (cheatedRaw is List) {
      // Firebase converted your map into a list -> convert back manually
      for (int i = 0; i < cheatedRaw.length; i++) {
        final v = cheatedRaw[i];
        if (v != null) {
          cheatedMap[i] = v.toString();
        }
      }
    }
    return StudentData(
      student: Student(
        uid: json['uid'] ?? json['id'],
        name: json['name'],
        joinedAt: Helper.joinedTime(json['joinedAt']),
      ),
      answers: Map<String, dynamic>.from(json['answers'] as Map? ?? {}),
      cheated: cheatedMap,
      // cheated: Map<int, String?>.from(
      //   json['cheated'] is List
      //       ? Map<int, String?>.fromIterable(
      //           json['cheated'],
      //           key: (element) => json['cheated'].indexOf(element),
      //         )
      //       : Map<int, String?>.from(
      //           (json['cheated'] as Map? ?? {}).map(
      //             (key, value) => MapEntry(int.parse(key), value),
      //           ),
      //         ),
      // ),
      currentQuestionIndex: json['currentQuestionIndex'],
      currentSectionIndex: json['currentSectionIndex'],
      joinedAt: Helper.joinedTime(json['joinedAt']),
      finishedAt: json['finishedAt'] == null
          ? null
          : Helper.joinedTime(json['finishedAt']),
      score: json['score'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'student': student.toJson(),
    'answers': answers,
    'cheated': cheated,
    'currentQuestionIndex': currentQuestionIndex,
    'currentSectionIndex': currentSectionIndex,
    'joinedAt': joinedAt,
    'finishedAt': finishedAt,
    'score': score,
    'status': status,
  };
}

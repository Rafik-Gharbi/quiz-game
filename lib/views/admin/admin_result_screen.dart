import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:quiz_game/views/widgets/app_header.dart';

import '../../models/student_data.dart';
import '../../services/main_controller.dart';
import '../../services/theme/theme.dart';

class AdminResultsScreen extends StatelessWidget {
  static String routeName = '/quiz-results';

  const AdminResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (MainController.find.quizData == null) return Text('No Data!');
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      body: StreamBuilder<DatabaseEvent>(
        stream: MainController.find.dbStudentsRef.onValue,
        builder: (context, studentsSnapshot) {
          if (!studentsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final studentsData = studentsSnapshot.data?.snapshot.value;

          final students = <StudentData>[];

          if (studentsData != null) {
            final map = Map<String, dynamic>.from(studentsData as Map);

            map.forEach((key, value) {
              // value is another map
              final student = StudentData.fromJson(
                Map<String, dynamic>.from(value as Map<Object?, Object?>),
              );
              students.add(student);
            });
          }

          // Calculate section averages
          final sectionScores = <String, List<double>>{};
          for (var section in MainController.find.quizData!.sections) {
            sectionScores[section.name] = [];
          }

          for (var student in students) {
            int questionIndex = 0;
            final answers = student.answers;

            for (var section in MainController.find.quizData!.sections) {
              int correct = 0;
              int total = section.questions.length;

              for (int i = 0; i < section.questions.length; i++) {
                questionIndex++;
                final hasCheated =
                    student.cheated[questionIndex]?.isNotEmpty ?? false;
                final question = section.questions[i];
                final answer = answers['${section.name}_$i'];
                if (answer != null && !hasCheated) {
                  if (question.type == 'single') {
                    if (answer == question.correct[0]) correct++;
                  } else {
                    final userAnswers = List<int>.from(answer);
                    if (userAnswers.length == question.correct.length &&
                        userAnswers.every(
                          (a) => question.correct.contains(a),
                        )) {
                      correct++;
                    }
                  }
                }
              }

              sectionScores[section.name]!.add(
                total > 0 ? (correct / total) * 100 : 0,
              );
            }
          }

          // Calculate overall average
          double overallAvg = 0;
          if (students.isNotEmpty) {
            final totalScores = students.map((data) => data.score).toList();
            overallAvg =
                totalScores.reduce((a, b) => a + b) / totalScores.length;
          }

          students.sort((a, b) {
            final scoreComparison = b.score.compareTo(a.score);
            if (scoreComparison != 0) return scoreComparison;
            return a.finishedAt!.compareTo(b.finishedAt!);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    AppHeader(dense: true),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFA726),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFA726).withAlpha(80),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: const Text(
                              'Quiz Completed',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Average score of all students',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                '${overallAvg.toStringAsFixed(1)} points',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5B7FFF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Section Averages',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ...sectionScores.entries.map((entry) {
                            final avg = entry.value.isEmpty
                                ? 0.0
                                : entry.value.reduce((a, b) => a + b) /
                                      entry.value.length;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      Text(
                                        '${avg.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5B7FFF),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: avg / 100,
                                      minHeight: 10,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF5B7FFF),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Final Leaderboard',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              TextButton(
                                onPressed: () => MainController.find.cancelRoom(
                                  isAdmin: true,
                                ),
                                child: Row(
                                  spacing: 8,
                                  children: [
                                    Icon(Icons.refresh_outlined),
                                    Text(
                                      'New Room',
                                      style: AppFonts.x14Regular,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Top performers in this quiz',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ...students.map((student) {
                            final index = students.indexOf(student);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: index == 0
                                          ? const Color(0xFFFFA726)
                                          : index == 1
                                          ? const Color(0xFFBDBDBD)
                                          : index == 2
                                          ? const Color(0xFFD4A574)
                                          : const Color(
                                              0xFF5B7FFF,
                                            ).withAlpha(60),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: index < 3
                                              ? Colors.white
                                              : const Color(0xFF5B7FFF),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      student.student.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${student.score} points',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5B7FFF),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

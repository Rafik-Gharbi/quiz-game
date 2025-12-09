import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:quiz_games/models/student_data.dart';
import 'package:quiz_games/services/theme/theme.dart';
import 'package:quiz_games/utils/constants/colors.dart';
import 'package:quiz_games/utils/helper.dart';
import 'package:quiz_games/views/widgets/app_header.dart';

import '../../services/main_controller.dart';

class StudentResultScreen extends StatelessWidget {
  static String routeName = '/student-result';

  const StudentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (MainController.find.quizData == null) return Text('No Data!');
    final quizData = MainController.find.quizData;
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      body: StreamBuilder<DatabaseEvent>(
        stream: MainController.find.dbCurrentStudentRef.onValue,
        builder: (context, studentSnapshot) {
          if (!studentSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = studentSnapshot.data!.snapshot.value;
          if (data == null) return Text('No Data!');

          MainController.find.studentData = StudentData.fromJson(
            Map<String, dynamic>.from(data as Map),
          );



          // Calculate wrong questions
          final wrongQuestions = <Map<String, dynamic>>[];
          final sectionsStats = <String, int>{};
          int questionIndex = 0;
          for (var section in quizData!.sections) {
            int correctAnswerInSection = 0;
            for (int i = 0; i < section.questions.length; i++) {
              questionIndex++;
              final question = section.questions[i];
              final hasCheated =
                  MainController
                      .find
                      .studentData!
                      .cheated[questionIndex]
                      ?.isNotEmpty ??
                  false;
              final answer = MainController
                  .find
                  .studentData!
                  .answers['${section.name}_$i'];

              bool isCorrect = false;
              if (answer != null && !hasCheated) {
                if (question.type == 'single') {
                  isCorrect = answer == question.correct[0];
                } else {
                  final userAnswers = answer is List
                      ? List<int>.from(answer)
                      : [];
                  isCorrect =
                      userAnswers.length == question.correct.length &&
                      userAnswers.every((a) => question.correct.contains(a));
                }
              }

              if (!isCorrect || hasCheated) {
                wrongQuestions.add({
                  'section': section.name,
                  'question': question.question,
                  'hasCheated': hasCheated,
                  'correctAnswer': question.correct
                      .map((idx) => question.options[idx].text)
                      .join(', '),
                  'userAnswer': answer != null
                      ? (question.type == 'single'
                            ? question.options[answer].text
                            : (answer as List)
                                  .map((idx) => question.options[idx].text)
                                  .join(', '))
                      : 'Not answered',
                });
              } else if (!hasCheated) {
                correctAnswerInSection++;
              }
            }
            sectionsStats.putIfAbsent(
              section.name,
              () => correctAnswerInSection,
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 34),
                  AppHeader(dense: true),
                  const SizedBox(height: 34),
                  // Score Header
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
                    child: Row(
                      spacing: 15,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text(
                                  'Quiz Complete!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Great job, ${MainController.find.currentStudent!.name}!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Your Score',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              // const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${MainController.find.studentData!.score} points',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5B7FFF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats per section
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Sections Breakdown',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(
                          sectionsStats.entries.length,
                          (index) => Column(
                            children: [
                              ListTile(
                                dense: true,
                                title: Text(
                                  '${sectionsStats.entries.elementAt(index).key}:',
                                  style: AppFonts.x14Regular,
                                ),
                                trailing: Text(
                                  '${sectionsStats.entries.elementAt(index).value} points',
                                  style: AppFonts.x14Bold.copyWith(
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ),
                              if (index < sectionsStats.entries.length - 1)
                                Divider(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (wrongQuestions.isNotEmpty) ...[
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
                      child: Theme(
                        data: ThemeData(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Review Wrong Answers',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Here are the questions you got wrong',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          childrenPadding: EdgeInsets.only(top: 24),
                          children: wrongQuestions.map((wq) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFB74D),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB74D),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      wq['section'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    wq['question'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      if (!Helper.isMobile() &&
                                          wq['hasCheated'] == true) ...[
                                        _buildCheatingDetectedCard(),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Column(
                                          children: [
                                            if (Helper.isMobile() &&
                                                wq['hasCheated'] == true) ...[
                                              _buildCheatingDetectedCard(),
                                              const SizedBox(height: 8),
                                            ],
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                    Icons.close,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          'Your Answer',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          wq['userAnswer'],
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                color: Color(
                                                                  0xFF2C3E50,
                                                                ),
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                    Icons.check,
                                                    color: Colors.green,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          'Correct Answer',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          wq['correctAnswer'],
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                color: Color(
                                                                  0xFF2C3E50,
                                                                ),
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
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
                              'Leaderboard',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            TextButton(
                              onPressed: () => MainController.find.cancelRoom(),
                              child: Row(
                                spacing: 8,
                                children: [
                                  Icon(Icons.refresh_outlined),
                                  Text(
                                    'Join New Quiz',
                                    style: AppFonts.x14Regular,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your ranking will update as other players finish...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        StreamBuilder<DatabaseEvent>(
                          stream: MainController.find.dbStudentsRef
                              .orderByChild('status')
                              .equalTo('finished')
                              .onValue,

                          builder: (context, leaderboardSnapshot) {
                            if (!leaderboardSnapshot.hasData) {
                              return const CircularProgressIndicator();
                            }

                            final studentsData =
                                leaderboardSnapshot.data?.snapshot.value;

                            final students = <Map<String, dynamic>>[];

                            if (studentsData != null) {
                              final map = Map<String, dynamic>.from(
                                studentsData as Map,
                              );

                              map.forEach((key, value) {
                                // value is another map
                                final student = Map<String, dynamic>.from(
                                  value,
                                );
                                student['uid'] =
                                    key; // optionally include the UID
                                students.add(student);
                              });
                            }

                            students.sort((a, b) {
                              final scoreA = a['score'] ?? 0;
                              final scoreB = b['score'] ?? 0;
                              return scoreB.compareTo(scoreA);
                            });

                            return Column(
                              children: students.asMap().entries.map((entry) {
                                final index = entry.key;
                                final student = entry.value;
                                final isCurrentStudent =
                                    entry.value['uid'] ==
                                    MainController.find.currentStudent!.uid;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isCurrentStudent
                                        ? const Color(0xFF5B7FFF).withAlpha(25)
                                        : const Color(0xFFF5F7FA),
                                    border: Border.all(
                                      color: isCurrentStudent
                                          ? const Color(0xFF5B7FFF)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
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
                                                ).withAlpha(55),
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
                                          student['name'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isCurrentStudent
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: const Color(0xFF2C3E50),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${student['score']} points',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5B7FFF),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Container _buildCheatingDetectedCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_outlined, color: Colors.red, size: 20),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              'Cheating detected!',
              softWrap: true,
              textAlign: TextAlign.center,
              style: AppFonts.x12Regular.copyWith(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

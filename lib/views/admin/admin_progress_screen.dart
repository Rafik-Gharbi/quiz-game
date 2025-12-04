import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_games/views/widgets/app_header.dart';

import '../../services/main_controller.dart';
import 'admin_result_screen.dart';

class AdminQuizProgressScreen extends StatelessWidget {
  final String roomCode;

  const AdminQuizProgressScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: StreamBuilder<DatabaseEvent>(
            stream: MainController.find.dbStudentsRef.onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final studentsData = snapshot.data?.snapshot.value;

              final students = <Map<String, dynamic>>[];

              if (studentsData != null) {
                final map = Map<String, dynamic>.from(studentsData as Map);

                map.forEach((key, value) {
                  // value is another map
                  final student = Map<String, dynamic>.from(value);
                  student['uid'] = key; // optionally include the UID
                  students.add(student);
                });
              }
              final allFinished = students.every((data) {
                return data['status'] == 'finished';
              });

              if (allFinished && students.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminResultsScreen(roomCode: roomCode),
                    ),
                  );
                });
              }

              return Column(
                children: [
                  AppHeader(dense: true),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
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
                            children: [
                              const Icon(
                                Icons.trending_up,
                                color: Color(0xFF5B7FFF),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Player Progress',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Live Updates',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: ListView.builder(
                              itemCount: students.length,
                              itemBuilder: (context, index) {
                                final student = students[index];
                                final progress =
                                    (student['indexFromTotalQuestions'] ?? 0);
                                final status = student['status'] ?? 'active';
                                final isFinished = status == 'finished';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isFinished
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFF5B7FFF),
                                        radius: 20,
                                        child: Text(
                                          student['name'][0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student['name'],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2C3E50),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isFinished
                                                  ? 'Completed Quiz'
                                                  : 'Question $progress',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isFinished)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF4CAF50),
                                          size: 28,
                                        )
                                      else
                                        Stack(
                                          children: [
                                            SizedBox(
                                              width: Get.width * 0.4,
                                              height: 24,
                                              child: LinearProgressIndicator(
                                                value:
                                                    progress /
                                                    MainController
                                                        .find
                                                        .questionsNumber,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                minHeight: 10,
                                                backgroundColor: Colors.grey,
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                      Color
                                                    >(Color(0xFF5B7FFF)),
                                              ),
                                            ),
                                            Positioned.fill(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 1,
                                                ),
                                                child: Text(
                                                  '${progress / MainController.find.questionsNumber * 100}%',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

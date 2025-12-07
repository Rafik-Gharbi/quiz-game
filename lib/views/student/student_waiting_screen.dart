import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_games/services/anti_cheating_service.dart';
import 'package:quiz_games/views/student/student_result_screen.dart';
import 'package:quiz_games/views/widgets/app_header.dart';

import '../../models/student.dart';
import '../../services/main_controller.dart';
import '../../services/theme/theme.dart';
import 'student_quiz_screen.dart';

class StudentWaitingScreen extends StatelessWidget {
  const StudentWaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      body: StreamBuilder<DatabaseEvent>(
        stream: MainController.find.dbRoomRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.snapshot.value;
          if (data == null) return Text('No Data!');

          final roomData = Map<String, dynamic>.from(data as Map);

          final status = roomData['status'];

          AntiCheatingService.find.checkFullscreenEnabled(force: true);
          if (status == 'active' && !MainController.find.studentIsFinished) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => Get.to(() => StudentQuizScreen()),
            );
          }
          if (MainController.find.studentIsFinished) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => Get.to(() => StudentResultScreen()),
            );
          }

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    const SizedBox(height: 34),
                    AppHeader(dense: true),
                    const SizedBox(height: 34),
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(40),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF5B7FFF).withAlpha(25),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.hourglass_empty,
                                    size: 50,
                                    color: Color(0xFF5B7FFF),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF5B7FFF),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Waiting for Admin',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'The quiz will begin shortly...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          buildRoomInfo(
                            Icons.wifi_outlined,
                            'Room Code: ${MainController.find.roomCode}',
                          ),
                          const SizedBox(height: 16),
                          buildRoomInfo(
                            Icons.sports_esports_outlined,
                            'Welcome! ${MainController.find.currentStudent!.name}',
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<DatabaseEvent>(
                            stream: MainController.find.dbStudentsRef.onValue,
                            builder: (context, studentsSnapshot) {
                              final studentsData =
                                  studentsSnapshot.data?.snapshot.value;

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
                                  if (!MainController.find.students.any(
                                    (element) => element.uid == key,
                                  )) {
                                    MainController.find.students.add(
                                      Student.fromJson(student),
                                    );
                                  }
                                });
                              }

                              return Obx(
                                () => buildRoomInfo(
                                  Icons.people,
                                  '${MainController.find.students.length} Players Joined',
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: MainController.find.cancelRoom,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [
                                Icon(Icons.refresh_outlined),
                                Text(
                                  'Join Another Room',
                                  style: AppFonts.x14Regular,
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
            ),
          );
        },
      ),
    );
  }

  Container buildRoomInfo(IconData icon, String value) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Color(0xFF5B7FFF), size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart' show ClipboardData, Clipboard;
import 'package:get/get.dart';
import 'package:quiz_games/models/section.dart';
import 'package:quiz_games/models/student.dart';
import 'package:quiz_games/services/theme/theme.dart';
import 'package:quiz_games/views/admin/admin_result_screen.dart';
import 'package:quiz_games/views/widgets/app_header.dart';

import '../../services/main_controller.dart';
import 'admin_progress_screen.dart';

class AdminWaitingRoomScreen extends StatelessWidget {
  static String routeName = '/admin-lobby';

  const AdminWaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roomCode = MainController.find.roomCode!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final joinedStudentsPerRow = ((constraints.maxWidth - 100) / 150)
            .toInt();
        final sectionsStatsPerRow = (constraints.maxWidth) / 250;
        final sectionsStatsWidth = (constraints.maxWidth) / sectionsStatsPerRow;
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
              final sections = MainController.find.quizData!.sections;
              final questions = sections
                  .map((e) => e.questions.length)
                  .reduce((value, element) => value + element);
              final students = MainController.find.students;

              if (status == 'active') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminQuizProgressScreen(),
                    ),
                  );
                });
              }
              if (status == 'finished') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => AdminResultsScreen()),
                  );
                });
              }

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      AppHeader(dense: true),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Admin Panel',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    TextButton(
                                      onPressed: () => MainController.find
                                          .cancelRoom(isAdmin: true),
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
                                Container(
                                  width: 250,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Room Code',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 50,
                                            child: IconButton(
                                              onPressed: () =>
                                                  Clipboard.setData(
                                                    ClipboardData(
                                                      text: roomCode,
                                                    ),
                                                  ),
                                              icon: Icon(Icons.copy_outlined),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        roomCode,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5B7FFF),
                                          letterSpacing: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 32),
                            Row(
                              children: [
                                BuildQuizStats(
                                  label: "Sections",
                                  value: sections.length.toString(),
                                ),
                                SizedBox(width: 20),
                                BuildQuizStats(
                                  label: "Questions",
                                  value: questions.toString(),
                                ),
                                SizedBox(width: 20),
                                Obx(
                                  () => BuildQuizStats(
                                    label: "Players",
                                    value: students.length.toString(),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 32),
                            Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              children: List.generate(
                                sections.length,
                                (index) => SizedBox(
                                  width: sectionsStatsWidth,
                                  child: BuildSectionStats(
                                    section: sections[index],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
                              final student = Map<String, dynamic>.from(value);
                              student['uid'] =
                                  key; // optionally include the UID
                              if (!students.any(
                                (element) => element.uid == key,
                              )) {
                                SchedulerBinding.instance.addPostFrameCallback(
                                  (_) =>
                                      students.add(Student.fromJson(student)),
                                );
                              }
                            });
                          }

                          return Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Obx(
                              () => Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.people,
                                        color: Color(0xFF5B7FFF),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${students.length} Joined Players',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  students.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.person_add_alt_1,
                                                size: 64,
                                                color: Colors.grey.shade300,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Waiting for students to join...',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount:
                                                    joinedStudentsPerRow,
                                                mainAxisSpacing: 16,
                                                crossAxisSpacing: 16,
                                                childAspectRatio: 0.8,
                                              ),
                                          itemCount: students.length,
                                          itemBuilder: (context, index) {
                                            final student = students[index];
                                            return Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F7FA),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  CircleAvatar(
                                                    backgroundColor:
                                                        const Color(0xFF5B7FFF),
                                                    radius: 24,
                                                    child: Text(
                                                      student.name[0]
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    student.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Joined at: ${student.joinedAt}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF4CAF50,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Ready',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: students.isEmpty
                                          ? null
                                          : () => _startQuiz(roomCode),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF4CAF50,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        disabledBackgroundColor:
                                            Colors.grey.shade300,
                                      ),
                                      child: const Text(
                                        'Start Quiz',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _startQuiz(String roomCode) async {
    await MainController.find.dbRoomRef.update({
      'status': 'active',
      'startedAt': ServerValue.timestamp,
    });
  }
}

class BuildQuizStats extends StatelessWidget {
  final String label;
  final String value;
  const BuildQuizStats({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 219, 233, 255),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          spacing: 10,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class BuildSectionStats extends StatelessWidget {
  final Section section;
  const BuildSectionStats({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 229, 254, 230),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 10,
        children: [
          Text(section.name, style: TextStyle(fontSize: 18)),
          Text(
            '${section.questions.length} questions',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:quiz_game/models/student.dart';
import 'package:quiz_game/services/shared_preferences.dart';
import 'package:quiz_game/services/randomization_service.dart';
import 'package:quiz_game/utils/constants/shared_preferences_keys.dart';
import 'package:quiz_game/views/admin/admin_screen.dart';
import 'package:quiz_game/views/student/student_screen.dart';

import '../models/quiz_data.dart';
import '../models/student_data.dart';
import '../utils/helper.dart';
import '../views/admin/admin_waiting_room.dart';
import '../views/student/student_waiting_screen.dart';

class MainController extends GetxController {
  static MainController find = Get.find<MainController>();
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref('rooms');
  String? roomCode;
  QuizData? quizData;
  Student? currentStudent;
  RxList<Student> students = <Student>[].obs;
  String? userUid;
  StudentData? studentData;
  int indexFromTotalQuestions = 0;
  bool studentIsFinished = false;

  // Randomization options
  bool randomizeQuestions = false;
  bool randomizeAnswers = false;

  DatabaseReference get dbRoomRef => dbRef.child(roomCode!);
  DatabaseReference get dbStudentsRef => dbRef.child('${roomCode!}/students');
  DatabaseReference get dbCurrentStudentRef =>
      dbRef.child('${roomCode!}/students/${currentStudent!.uid}');
  int get questionsNumber => quizData == null
      ? 0
      : quizData!.sections
            .map((e) => e.questions.length)
            .reduce((value, element) => value + element);

  Future<void> createRoom(String text) async {
    try {
      final jsonData = json.decode(text);
      var quizDataTemp = QuizData.fromJson(jsonData);

      quizData = quizDataTemp;
      // Generate room code
      roomCode = await _generateRoomCode();
      // Create room in Firestore
      await dbRef.child(roomCode!).set({
        'code': roomCode,
        'admin': FirebaseAuth.instance.currentUser?.uid,
        'quizData': quizData!.toJson(),
        'randomizeQuestions': randomizeQuestions,
        'randomizeAnswers': randomizeAnswers,
        'status': 'waiting', // waiting, active, finished, canceled
        'createdAt': ServerValue.timestamp,
      });
      _saveRoom('admin');
      Get.to(() => AdminWaitingRoomScreen());
    } catch (e) {
      debugPrint('Error creating room: $e');
      Helper.snackBar(message: 'Error creating room: $e');
    }
  }

  Future<void> joinRoom(String code, String studentName) async {
    try {
      await FirebaseAuth.instance.authStateChanges().firstWhere(
        (user) => user != null,
      );
      final user = FirebaseAuth.instance.currentUser;
      debugPrint("Signed in as: ${user?.uid}");
      final roomDoc = await dbRef.child(code.toUpperCase()).get();
      if (!roomDoc.exists) {
        throw Exception('Room not found');
      }
      if (user?.uid == null) {
        throw Exception('User not logged in');
      }
      userUid = user!.uid;
      roomCode = code.toUpperCase();
      currentStudent = Student(
        uid: userUid!,
        name: studentName,
        joinedAt: DateTime.now().toIso8601String(),
      );
      await dbCurrentStudentRef.set({
        'id': currentStudent!.uid,
        'name': currentStudent!.name,
        'status': 'waiting',
        'joinedAt': ServerValue.timestamp,
        'currentQuestionIndex': 0,
        'currentSectionIndex': 0,
        'indexFromTotalQuestions': 0,
        'answers': {},
        'cheated': {},
        'score': 0,
      });
      _saveRoom('student', studentUid: currentStudent!.uid);
      await _initializeRoom(code);
      Get.to(() => StudentWaitingScreen());
    } catch (e) {
      debugPrint('Error joining room: $e');
      Helper.snackBar(message: 'Error joining room: $e');
    }
  }

  void _saveRoom(String role, {String? studentUid}) {
    SharedPreferencesService().add(roomCodeKey, roomCode!);
    SharedPreferencesService().add(
      roomDateKey,
      DateTime.now().toIso8601String(),
    );
    SharedPreferencesService().add(roomRoleKey, role);
    if (studentUid != null) {
      SharedPreferencesService().add(roomStudentKey, studentUid);
    }
  }

  Future<String> _generateRoomCode([int length = 6]) async {
    while (true) {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rand = Random.secure();
      final code = String.fromCharCodes(
        Iterable.generate(
          length,
          (_) => chars.codeUnitAt(rand.nextInt(chars.length)),
        ),
      );

      final snap = await dbRef.child(code).get();
      if (!snap.exists) return code;
    }
  }

  Future<void> _initializeRoom(String code, {String? studentUid}) async {
    final roomDoc = await dbRef.child(code).get();
    final data = roomDoc.value;
    if (data == null) {
      debugPrint('Room not found');
      return;
    }
    final roomData = Map<String, dynamic>.from(data as Map<Object?, Object?>);
    if (roomData['status'] == 'waiting' || roomData['status'] == 'active') {
      roomCode = code;
      quizData = QuizData.fromJson(
        jsonDecode(jsonEncode(roomData['quizData'])),
      );
      // Apply randomization if configured
      randomizeQuestions = roomData['randomizeQuestions'] ?? false;
      randomizeAnswers = roomData['randomizeAnswers'] ?? false;
      if (randomizeQuestions || randomizeAnswers) {
        quizData = RandomizationService().randomizeQuiz(
          quizData: quizData!,
          randomizeQuestions: randomizeQuestions,
          randomizeAnswers: randomizeAnswers,
        );
      }

      if (studentUid != null) {
        debugPrint(roomCode);
        final studentDoc = await dbRef
            .child('${roomCode!}/students/$studentUid')
            .get();
        final student = studentDoc.value;
        if (student == null) {
          debugPrint('Student not found');
          return;
        }
        studentData = StudentData.fromJson(
          Map<String, dynamic>.from(student as Map<Object?, Object?>),
        );
        currentStudent = studentData!.student;
        studentIsFinished = studentData!.status == 'finished';
      }
    } else {
      _clearSavedRoom();
    }
  }

  Future<void> checkSavedRoom() async {
    final savedRoomCode = SharedPreferencesService().get(roomCodeKey);
    if (savedRoomCode == null) return;
    final savedRoomDate = DateTime.tryParse(
      SharedPreferencesService().get(roomDateKey) ?? '',
    );
    if (savedRoomDate == null ||
        savedRoomDate.difference(DateTime.now()).inMinutes > 60) {
      _clearSavedRoom();
      return;
    }
    final savedRole = SharedPreferencesService().get(roomRoleKey);
    if (savedRole == null) {
      _clearSavedRoom();
      return;
    }
    if (savedRole == 'admin') {
      await _initializeRoom(savedRoomCode);
      Get.to(() => AdminWaitingRoomScreen());
    } else if (savedRole == 'student') {
      final savedStudent = SharedPreferencesService().get(roomStudentKey);
      if (savedStudent == null) {
        _clearSavedRoom();
        return;
      }
      await _initializeRoom(savedRoomCode, studentUid: savedStudent);
      Get.to(() => StudentWaitingScreen());
    }
  }

  void _clearSavedRoom() {
    SharedPreferencesService().removeKey(roomCodeKey);
    SharedPreferencesService().removeKey(roomDateKey);
    SharedPreferencesService().removeKey(roomRoleKey);
  }

  void cancelRoom({bool isAdmin = false}) {
    _clearSavedRoom();
    if (isAdmin) {
      dbRoomRef.update({'status': 'canceled'});
      Get.to(() => AdminScreen());
    } else {
      studentIsFinished = false;
      SharedPreferencesService().removeKey(roomStudentKey);
      Get.to(() => StudentScreen());
    }
  }
}

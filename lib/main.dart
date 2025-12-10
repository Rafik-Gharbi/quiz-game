import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:quiz_game/services/anti_cheating_service.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:quiz_game/views/admin/admin_progress_screen.dart';
import 'package:quiz_game/views/admin/admin_result_screen.dart';
import 'package:quiz_game/views/admin/admin_screen.dart';
import 'package:quiz_game/views/admin/admin_waiting_room.dart';
import 'package:quiz_game/views/student/student_quiz_screen.dart';
import 'package:quiz_game/views/student/student_result_screen.dart';
import 'package:quiz_game/views/student/student_screen.dart';
import 'package:quiz_game/views/student/student_waiting_screen.dart';

import 'services/main_controller.dart';
import 'services/shared_preferences.dart';
import 'views/home/home_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  usePathUrlStrategy();
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Quiz App',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        initialBinding: InitialBindings(),
        // home: const HomeScreen(),
        initialRoute: HomeScreen.routeName,
        getPages: [
          GetPage(name: HomeScreen.routeName, page: () => const HomeScreen()),
          GetPage(
            name: StudentScreen.routeName,
            page: () => const StudentScreen(),
          ),
          GetPage(
            name: StudentWaitingScreen.routeName,
            page: () => const StudentWaitingScreen(),
          ),
          GetPage(
            name: StudentQuizScreen.routeName,
            page: () => const StudentQuizScreen(),
          ),
          GetPage(
            name: StudentResultScreen.routeName,
            page: () => const StudentResultScreen(),
          ),
          GetPage(name: AdminScreen.routeName, page: () => const AdminScreen()),
          GetPage(
            name: AdminWaitingRoomScreen.routeName,
            page: () => const AdminWaitingRoomScreen(),
          ),
          GetPage(
            name: AdminQuizProgressScreen.routeName,
            page: () => const AdminQuizProgressScreen(),
          ),
          GetPage(
            name: AdminResultsScreen.routeName,
            page: () => const AdminResultsScreen(),
          ),
        ],
      ),
    );
  }
}

class InitialBindings implements Bindings {
  @override
  void dependencies() {
    // Controllers & Services
    Get.put(SharedPreferencesService(), permanent: true);
    Get.put(MainController(), permanent: true);
    Get.put(AntiCheatingService(), permanent: true);
  }
}

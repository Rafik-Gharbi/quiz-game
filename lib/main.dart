import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:quiz_games/services/anti_cheating_service.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

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
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialBinding: InitialBindings(),
      home: const HomeScreen(),
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


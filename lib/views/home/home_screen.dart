import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_game/services/main_controller.dart';
import 'package:quiz_game/views/widgets/app_header.dart';

import '../admin/admin_screen.dart';
import '../student/student_screen.dart';
import 'components/role_button.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = '/';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _signInUser();
  }

  Future<void> _signInUser() async {
    try {
      final result = await FirebaseAuth.instance.signInAnonymously();
      if (result.user?.uid != null) {
        debugPrint('Signed in successfully ${result.user?.uid}');
        MainController.find.userUid = result.user!.uid;
        WidgetsBinding.instance.addPostFrameCallback(
          (duration) => Future.delayed(
            Duration(seconds: 1),
            () => MainController.find.checkSavedRoom(),
          ),
        );
      } else {
        throw Exception('user is null');
      }
    } catch (e) {
      debugPrint("Error occured $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 800),
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
              AppHeader(),
              const SizedBox(height: 40),
              const Text(
                'Choose Your Role',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 20),
              RoleButton(
                label: 'Join as Admin',
                color: const Color(0xFF5B7FFF),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                ),
              ),
              const SizedBox(height: 12),
              RoleButton(
                label: 'Join as Student',
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

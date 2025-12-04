import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class AppHeader extends StatelessWidget {
  final bool dense;
  const AppHeader({super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final headerSubtitle = Text(
      'Take part in an engaging quiz with your peers',
      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
      textAlign: TextAlign.center,
    );
    const headerTitle = Text(
      'Interactive Quiz App',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
      ),
    );
    final headerIcon = Container(
      padding: EdgeInsets.all(dense ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF5B7FFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(quizIcon, size: dense ? 28 : 48, color: Colors.white),
    );
    return dense
        ? Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [headerIcon, const SizedBox(width: 24), headerTitle],
              ),
              const SizedBox(height: 8),
              headerSubtitle,
            ],
          )
        : Column(
            children: [
              headerIcon,
              const SizedBox(height: 24),
              headerTitle,
              const SizedBox(height: 8),
              headerSubtitle,
            ],
          );
  }
}

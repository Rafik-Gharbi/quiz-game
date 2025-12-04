import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_games/utils/constants/colors.dart';

import '../../models/quiz_data.dart';
import '../../services/main_controller.dart';
import 'student_result_screen.dart';

class StudentQuizScreen extends StatefulWidget {
  const StudentQuizScreen({super.key});

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  final Set<int> _selectedMultiple = {};
  final Map<String, dynamic> _answers = {};
  int _currentSectionIndex = 0;
  int _currentQuestionIndex = 0;
  int _totalQuestions = 0;
  int _indexFromTotalQuestions = 1;
  dynamic _selectedAnswer;
  Timer? _timer;
  int _timeRemaining = 0;
  QuizData? _quizData;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
    _totalQuestions = MainController.find.questionsNumber;
  }

  Future<void> _loadQuizData() async {
    final roomDoc = await MainController.find.dbRoomRef.get();

    final data = roomDoc.value;
    if (data == null) {
      debugPrint('Room not found');
      return;
    }

    final roomData = Map<String, dynamic>.from(data as Map<Object?, Object?>);

    setState(() {
      _quizData = QuizData.fromJson(
        Map<String, dynamic>.from(roomData['quizData'] as Map),
      );
      _startTimer();
    });
  }

  void _startTimer() {
    if (_quizData == null) return;

    final question = _quizData!
        .sections[_currentSectionIndex]
        .questions[_currentQuestionIndex];
    _timeRemaining = question.timeLimit;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _submitAnswer();
      }
    });
  }

  Future<void> _submitAnswer() async {
    _timer?.cancel();

    final section = _quizData!.sections[_currentSectionIndex];
    final answerKey = '${section.name}_$_currentQuestionIndex';
    _answers[answerKey] = _selectedAnswer;

    await MainController.find.dbCurrentStudentRef.update({
      'answers': _answers,
      'indexFromTotalQuestions': _indexFromTotalQuestions,
      'currentQuestionIndex': _currentQuestionIndex + 1,
      'currentSectionIndex': _currentSectionIndex,
    });

    // Move to next question or section
    if (_currentQuestionIndex < section.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _indexFromTotalQuestions++;
        _selectedAnswer = null;
        _selectedMultiple.clear();
        _startTimer();
      });
    } else if (_currentSectionIndex < _quizData!.sections.length - 1) {
      setState(() {
        _currentSectionIndex++;
        _indexFromTotalQuestions++;
        _currentQuestionIndex = 0;
        _selectedAnswer = null;
        _selectedMultiple.clear();
        _startTimer();
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    _timer?.cancel();

    // Calculate score
    int totalCorrect = 0;

    for (var section in _quizData!.sections) {
      for (int i = 0; i < section.questions.length; i++) {
        final question = section.questions[i];
        final answer = _answers['${section.name}_$i'];

        if (answer != null) {
          if (question.type == 'single') {
            if (answer == question.correct[0]) totalCorrect++;
          } else {
            final userAnswers = answer is List ? List<int>.from(answer) : [];
            if (userAnswers.length == question.correct.length &&
                userAnswers.every((a) => question.correct.contains(a))) {
              totalCorrect++;
            }
          }
        }
      }
    }

    await MainController.find.dbCurrentStudentRef.update({
      'status': 'finished',
      'score': totalCorrect,
      'finishedAt': ServerValue.timestamp,
    });
    MainController.find.studentIsFinished = true;

    Get.to(() => StudentResultScreen());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_quizData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final section = _quizData!.sections[_currentSectionIndex];
    final question = section.questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: DecoratedBox(
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Section: ${section.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      // Timer Coundown
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 20,
                            color: _timeRemaining <= 10
                                ? Colors.red
                                : const Color(0xFF5B7FFF),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_timeRemaining s',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _timeRemaining <= 10
                                  ? Colors.red
                                  : const Color(0xFF5B7FFF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question $_indexFromTotalQuestions of $_totalQuestions',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        '${(_indexFromTotalQuestions - 1) / _totalQuestions * 100}% Complete',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_indexFromTotalQuestions - 1) / _totalQuestions,
                    backgroundColor: kNeutralLightColor,
                    color: kPrimaryColor.withAlpha(180),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _timeRemaining.toDouble() / question.timeLimit,
                    backgroundColor: kNeutralLightColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(6),
                    color: kErrorColor.withAlpha(180),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.type == 'multiple'
                        ? 'Select all correct answers'
                        : 'Select one correct answer',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView.builder(
                      itemCount: question.options.length,
                      itemBuilder: (context, index) {
                        if (question.type == 'single') {
                          return _buildSingleOption(
                            index,
                            question.options[index],
                          );
                        } else {
                          return _buildMultipleOption(
                            index,
                            question.options[index],
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          _selectedAnswer != null ||
                              _selectedMultiple.isNotEmpty
                          ? _submitAnswer
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: const Text(
                        'Submit',
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
          ),
        ),
      ),
    );
  }

  Widget _buildSingleOption(int index, String option) {
    final isSelected = _selectedAnswer == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedAnswer = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5B7FFF).withAlpha(25)
              : const Color(0xFFF5F7FA),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B7FFF) : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5B7FFF)
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF5B7FFF) : Colors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected
                      ? const Color(0xFF5B7FFF)
                      : const Color(0xFF2C3E50),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleOption(int index, String option) {
    final isSelected = _selectedMultiple.contains(index);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMultiple.remove(index);
          } else {
            _selectedMultiple.add(index);
          }
          _selectedAnswer = _selectedMultiple.toList();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5B7FFF).withAlpha(25)
              : const Color(0xFFF5F7FA),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B7FFF) : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5B7FFF)
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF5B7FFF) : Colors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected
                      ? const Color(0xFF5B7FFF)
                      : const Color(0xFF2C3E50),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

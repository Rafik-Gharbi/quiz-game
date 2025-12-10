import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_game/services/anti_cheating_service.dart';
import 'package:quiz_game/utils/constants/colors.dart';

import '../../models/question.dart';
import '../../services/main_controller.dart';
import 'student_result_screen.dart';

class StudentQuizScreen extends StatefulWidget {
  static String routeName = '/quiz';

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
  dynamic _selectedAnswer;
  Timer? _timer;
  double _timeRemaining = 0;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
    _totalQuestions = MainController.find.questionsNumber;
    MainController.find.studentData?.status = 'active';
    MainController.find.indexFromTotalQuestions = 1;
  }

  Future<void> _loadQuizData() async {
    final roomDoc = await MainController.find.dbRoomRef.get();

    final data = roomDoc.value;
    if (data == null) {
      debugPrint('Room not found');
      return;
    }

    setState(() => _startTimer());
  }

  void _startTimer() {
    if (MainController.find.quizData == null) return;

    final question = MainController
        .find
        .quizData!
        .sections[_currentSectionIndex]
        .questions[_currentQuestionIndex];
    _timeRemaining = question.timeLimit.toDouble();

    _timer?.cancel();
    // Use new timer tracking method for iOS timer verification
    AntiCheatingService.find.startQuestionTimer(question);
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining -= 0.25);
      } else {
        _submitAnswer();
      }
    });
  }

  Future<void> _submitAnswer() async {
    _timer?.cancel();

    final section =
        MainController.find.quizData!.sections[_currentSectionIndex];
    final question = section.questions[_currentQuestionIndex];
    final answerKey = '${section.name}_$_currentQuestionIndex';
    _answers[answerKey] = _selectedAnswer;

    // Check question time and verify timer integrity (iOS app backgrounding detection)
    AntiCheatingService.find.checkQuestionTime(question);
    final isTimerValid = AntiCheatingService.find.verifyQuestionTimeIntegrity(
      question,
    );
    if (!isTimerValid) {
      debugPrint(
        '⚠️ Timer integrity check failed - possible app backgrounding detected',
      );
    }

    final cheating = AntiCheatingService.find.detectedCheatings.map(
      (e, v) => MapEntry<int, String>(e, v.join(',')),
    );
    debugPrint(
      'Question ${MainController.find.indexFromTotalQuestions} ${cheating.values.join(',')}',
    );
    await MainController.find.dbCurrentStudentRef.update({
      'answers': _answers,
      'cheated': cheating,
      'indexFromTotalQuestions': MainController.find.indexFromTotalQuestions,
      'currentQuestionIndex': MainController.find.indexFromTotalQuestions + 1,
      'currentSectionIndex': _currentSectionIndex,
    });

    // Move to next question or section
    if (_currentQuestionIndex < section.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        MainController.find.indexFromTotalQuestions++;
        _selectedAnswer = null;
        _selectedMultiple.clear();
        _startTimer();
      });
    } else if (_currentSectionIndex <
        MainController.find.quizData!.sections.length - 1) {
      setState(() {
        _currentSectionIndex++;
        MainController.find.indexFromTotalQuestions++;
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
    int indexQuestion = 0;

    for (var section in MainController.find.quizData!.sections) {
      for (int i = 0; i < section.questions.length; i++) {
        indexQuestion++;
        final question = section.questions[i];
        final hasCheated =
            AntiCheatingService
                .find
                .detectedCheatings[indexQuestion]
                ?.isNotEmpty ??
            false;
        final answer = _answers['${section.name}_$i'];

        if (answer != null && !hasCheated) {
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
    if (MainController.find.quizData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final section =
        MainController.find.quizData!.sections[_currentSectionIndex];
    final question = section.questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      body: SingleChildScrollView(
        child: Center(
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
                              '${_timeRemaining.toInt()} s',
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
                          'Question ${MainController.find.indexFromTotalQuestions} of $_totalQuestions',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          '${((MainController.find.indexFromTotalQuestions - 1) / _totalQuestions * 100).toInt()}% Complete',
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
                      value:
                          (MainController.find.indexFromTotalQuestions - 1) /
                          _totalQuestions,
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
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: question.options.length,
                      itemBuilder: (context, index) {
                        if (question.type == 'single') {
                          return _buildSingleOption(question.options[index]);
                        } else {
                          return _buildMultipleOption(question.options[index]);
                        }
                      },
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
      ),
    );
  }

  Widget _buildSingleOption(Answer answer) {
    final isSelected = _selectedAnswer == answer.index;
    return GestureDetector(
      onTap: () => setState(() => _selectedAnswer = answer.index),
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
                answer.text,
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

  Widget _buildMultipleOption(Answer answer) {
    final isSelected = _selectedMultiple.contains(answer.index);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMultiple.remove(answer.index);
          } else {
            _selectedMultiple.add(answer.index);
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
                answer.text,
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

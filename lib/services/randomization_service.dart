import 'dart:math';
import 'package:quiz_game/models/quiz_data.dart';
import 'package:quiz_game/models/section.dart';
import 'package:quiz_game/models/question.dart';

/// Service for handling randomization of questions and answers in quizzes
/// This allows admins to configure whether questions and/or answers should be randomized
class RandomizationService {
  static final RandomizationService _instance =
      RandomizationService._internal();

  factory RandomizationService() {
    return _instance;
  }

  RandomizationService._internal();

  final _random = Random();

  /// Randomizes the quiz data based on provided flags
  ///
  /// Parameters:
  /// - [quizData]: The original quiz data
  /// - [randomizeQuestions]: Whether to shuffle questions within each section
  /// - [randomizeAnswers]: Whether to shuffle answer options and update correct indices
  ///
  /// Returns: A new [QuizData] object with randomization applied
  QuizData randomizeQuiz({
    required QuizData quizData,
    required bool randomizeQuestions,
    required bool randomizeAnswers,
  }) {
    // If no randomization is needed, return original data
    if (!randomizeQuestions && !randomizeAnswers) {
      return quizData;
    }

    final randomizedSections = quizData.sections.map((section) {
      return _randomizeSection(
        section,
        randomizeQuestions: randomizeQuestions,
        randomizeAnswers: randomizeAnswers,
      );
    }).toList();
    randomizedSections.shuffle(_random);

    return QuizData(sections: randomizedSections);
  }

  /// Randomizes a single section
  Section _randomizeSection(
    Section section, {
    required bool randomizeQuestions,
    required bool randomizeAnswers,
  }) {
    var questions = List<Question>.from(section.questions);

    // Shuffle questions if requested
    if (randomizeQuestions) {
      questions.shuffle(_random);
    }

    // Randomize answers in each question if requested
    if (randomizeAnswers) {
      questions = questions.map((q) => _randomizeAnswers(q)).toList();
    }

    return Section(name: section.name, questions: questions);
  }

  /// Randomizes the answer options for a single question
  /// Updates the correct answer indices to match the new positions
  Question _randomizeAnswers(Question question) {
    question.options.shuffle(_random);
    return Question(
      question: question.question,
      type: question.type,
      options: question.options,
      correct: question.correct,
      timeLimit: question.timeLimit,
    );
  }

  /// Randomizes only the questions (not answers) in a quiz
  QuizData randomizeQuestionsOnly(QuizData quizData) {
    return randomizeQuiz(
      quizData: quizData,
      randomizeQuestions: true,
      randomizeAnswers: false,
    );
  }

  /// Randomizes only the answers (not questions) in a quiz
  QuizData randomizeAnswersOnly(QuizData quizData) {
    return randomizeQuiz(
      quizData: quizData,
      randomizeQuestions: false,
      randomizeAnswers: true,
    );
  }

  /// Randomizes both questions and answers in a quiz
  QuizData randomizeAll(QuizData quizData) {
    return randomizeQuiz(
      quizData: quizData,
      randomizeQuestions: true,
      randomizeAnswers: true,
    );
  }
}

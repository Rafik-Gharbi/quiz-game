// Example Unit Tests for RandomizationService
// Place this in: test/services/randomization_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_games/models/question.dart';
import 'package:quiz_games/models/quiz_data.dart';
import 'package:quiz_games/models/section.dart';
import 'package:quiz_games/services/randomization_service.dart';

void main() {
  group('RandomizationService', () {
    late RandomizationService service;

    setUp(() {
      service = RandomizationService();
    });

    group('randomizeQuestionsOnly', () {
      test('should shuffle questions within a section', () {
        final questions = [
          Question(
            question: 'Q1',
            type: 'single',
            options: ['A', 'B', 'C'],
            correct: [0],
            timeLimit: 30,
          ),
          Question(
            question: 'Q2',
            type: 'single',
            options: ['A', 'B', 'C'],
            correct: [1],
            timeLimit: 30,
          ),
          Question(
            question: 'Q3',
            type: 'single',
            options: ['A', 'B', 'C'],
            correct: [2],
            timeLimit: 30,
          ),
        ];

        final section = Section(name: 'Test', questions: questions);
        final quizData = QuizData(sections: [section]);

        final randomized = service.randomizeQuestionsOnly(quizData);

        // Questions should still be 3
        expect(randomized.sections[0].questions.length, 3);

        // All original questions should be present
        final originalQuestions = {'Q1', 'Q2', 'Q3'};
        final randomizedQuestions = randomized.sections[0].questions
            .map((q) => q.question)
            .toSet();
        expect(randomizedQuestions, originalQuestions);
      });

      test(
        'should not randomize answers when randomizeQuestionsOnly is called',
        () {
          final question = Question(
            question: 'Test',
            type: 'single',
            options: ['Alpha', 'Beta', 'Gamma'],
            correct: [0],
            timeLimit: 30,
          );

          final section = Section(name: 'Test', questions: [question]);
          final quizData = QuizData(sections: [section]);

          final randomized = service.randomizeQuestionsOnly(quizData);
          final randomizedQuestion = randomized.sections[0].questions[0];

          // Options should remain in original order
          expect(randomizedQuestion.options, ['Alpha', 'Beta', 'Gamma']);
          expect(randomizedQuestion.correct, [0]);
        },
      );
    });

    group('randomizeAnswersOnly', () {
      test('should shuffle answers and update correct indices', () {
        final question = Question(
          question: 'What is 2+2?',
          type: 'single',
          options: ['3', '4', '5', '6'],
          correct: [1], // '4' is correct
          timeLimit: 30,
        );

        final section = Section(name: 'Math', questions: [question]);
        final quizData = QuizData(sections: [section]);

        final randomized = service.randomizeAnswersOnly(quizData);
        final randomizedQuestion = randomized.sections[0].questions[0];

        // Options should be different
        expect(randomizedQuestion.options, isNot(['3', '4', '5', '6']));

        // But the correct answer should still be '4'
        expect(randomizedQuestion.options[randomizedQuestion.correct[0]], '4');
      });

      test('should handle multiple correct answers in multiple-choice', () {
        final question = Question(
          question: 'Select all prime numbers',
          type: 'multiple',
          options: ['2', '3', '4', '5', '6'],
          correct: [0, 1, 3], // 2, 3, 5 are prime
          timeLimit: 60,
        );

        final section = Section(name: 'Math', questions: [question]);
        final quizData = QuizData(sections: [section]);

        final randomized = service.randomizeAnswersOnly(quizData);
        final randomizedQuestion = randomized.sections[0].questions[0];

        // All correct answers should still point to primes
        final correctAnswers = randomizedQuestion.correct
            .map((i) => randomizedQuestion.options[i])
            .toSet();
        expect(correctAnswers, {'2', '3', '5'});
      });

      test('should not change question order when randomizeAnswersOnly', () {
        final questions = [
          Question(
            question: 'Q1',
            type: 'single',
            options: ['A', 'B'],
            correct: [0],
            timeLimit: 30,
          ),
          Question(
            question: 'Q2',
            type: 'single',
            options: ['A', 'B'],
            correct: [0],
            timeLimit: 30,
          ),
        ];

        final section = Section(name: 'Test', questions: questions);
        final quizData = QuizData(sections: [section]);

        final randomized = service.randomizeAnswersOnly(quizData);
        final randomizedQuestions = randomized.sections[0].questions
            .map((q) => q.question)
            .toList();

        expect(randomizedQuestions, ['Q1', 'Q2']);
      });
    });

    group('randomizeAll', () {
      test('should randomize both questions and answers', () {
        final questions = [
          Question(
            question: 'Q1',
            type: 'single',
            options: ['Option1', 'Option2'],
            correct: [0],
            timeLimit: 30,
          ),
          Question(
            question: 'Q2',
            type: 'single',
            options: ['Option3', 'Option4'],
            correct: [1],
            timeLimit: 30,
          ),
        ];

        final section = Section(name: 'Test', questions: questions);
        final quizData = QuizData(sections: [section]);

        final randomized = service.randomizeAll(quizData);

        // Question order might be different
        final randomizedQuestionTexts = randomized.sections[0].questions
            .map((q) => q.question)
            .toSet();
        expect(randomizedQuestionTexts, {'Q1', 'Q2'});

        // Verify correct answers are still mapped correctly
        for (final question in randomized.sections[0].questions) {
          if (question.question == 'Q1') {
            expect(question.options[question.correct[0]], 'Option1');
          } else if (question.question == 'Q2') {
            expect(question.options[question.correct[0]], 'Option4');
          }
        }
      });
    });

    group('randomizeQuiz with custom flags', () {
      test('should return same data when both flags are false', () {
        final questions = [
          Question(
            question: 'Q1',
            type: 'single',
            options: ['A', 'B', 'C'],
            correct: [0],
            timeLimit: 30,
          ),
        ];

        final section = Section(name: 'Test', questions: questions);
        final quizData = QuizData(sections: [section]);

        final result = service.randomizeQuiz(
          quizData: quizData,
          randomizeQuestions: false,
          randomizeAnswers: false,
        );

        // Should be identical
        expect(result.sections[0].questions[0].question, 'Q1');
        expect(result.sections[0].questions[0].options, ['A', 'B', 'C']);
        expect(result.sections[0].questions[0].correct, [0]);
      });

      test('should preserve all question data except order and options', () {
        final originalQuestion = Question(
          question: 'Original Question',
          type: 'multiple',
          options: ['Opt1', 'Opt2', 'Opt3'],
          correct: [0, 2],
          timeLimit: 45,
        );

        final section = Section(name: 'Test', questions: [originalQuestion]);
        final quizData = QuizData(sections: [section]);

        final randomized = service.randomizeAll(quizData);
        final randomizedQuestion = randomized.sections[0].questions[0];

        // Preserved fields
        expect(randomizedQuestion.question, 'Original Question');
        expect(randomizedQuestion.type, 'multiple');
        expect(randomizedQuestion.timeLimit, 45);

        // Options should be shuffled but contain same values
        expect(randomizedQuestion.options.toSet(), {'Opt1', 'Opt2', 'Opt3'});

        // Correct answers should map to same options
        expect(
          randomizedQuestion.correct
              .map((i) => randomizedQuestion.options[i])
              .toSet(),
          {'Opt1', 'Opt3'},
        );
      });
    });

    group('Multiple sections', () {
      test('should randomize each section independently', () {
        final section1 = Section(
          name: 'Math',
          questions: [
            Question(
              question: 'Math Q1',
              type: 'single',
              options: ['A', 'B'],
              correct: [0],
              timeLimit: 30,
            ),
            Question(
              question: 'Math Q2',
              type: 'single',
              options: ['C', 'D'],
              correct: [0],
              timeLimit: 30,
            ),
          ],
        );

        final section2 = Section(
          name: 'Science',
          questions: [
            Question(
              question: 'Science Q1',
              type: 'single',
              options: ['E', 'F'],
              correct: [0],
              timeLimit: 30,
            ),
          ],
        );

        final quizData = QuizData(sections: [section1, section2]);
        final randomized = service.randomizeQuestionsOnly(quizData);

        // Both sections should still exist
        expect(randomized.sections.length, 2);
        expect(randomized.sections[0].name, 'Math');
        expect(randomized.sections[1].name, 'Science');

        // Math section should have 2 questions
        expect(randomized.sections[0].questions.length, 2);

        // Science section should have 1 question
        expect(randomized.sections[1].questions.length, 1);
      });
    });
  });
}

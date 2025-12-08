# Randomization Service Documentation

## Overview

The `RandomizationService` is a dedicated service that handles randomization of quiz content. It allows admins to configure whether questions and/or answers should be randomized when creating a new quiz room. This feature is useful for preventing cheating and ensuring fair assessment across multiple quiz instances.

## Features

### 1. Question Randomization

- Shuffles the order of questions within each section
- Maintains the integrity of sections (sections themselves are not shuffled, only questions within them)
- Useful for ensuring students encounter questions in different orders

### 2. Answer Randomization

- Shuffles the order of answer options for each question
- **Automatically updates correct answer indices** to maintain accuracy
- Works seamlessly with both single-choice and multiple-choice questions
- Ensures the correct answers remain correct after shuffling

### 3. Combined Randomization

- Both questions and answers can be randomized together
- Or individually based on admin preference

## Service Methods

### `randomizeQuiz()`

The main method for applying randomization to quiz data.

```dart
QuizData randomizeQuiz({
  required QuizData quizData,
  required bool randomizeQuestions,
  required bool randomizeAnswers,
})
```

**Parameters:**

- `quizData`: The original quiz data structure
- `randomizeQuestions`: Whether to shuffle questions within sections
- `randomizeAnswers`: Whether to shuffle answer options

**Returns:** A new `QuizData` object with randomization applied

**Example:**

```dart
final randomizedQuiz = RandomizationService().randomizeQuiz(
  quizData: originalQuiz,
  randomizeQuestions: true,
  randomizeAnswers: true,
);
```

### Convenience Methods

```dart
// Randomize only questions
QuizData randomizeQuestionsOnly(QuizData quizData)

// Randomize only answers
QuizData randomizeAnswersOnly(QuizData quizData)

// Randomize both
QuizData randomizeAll(QuizData quizData)
```

## Integration with MainController

The `MainController` has been updated to support randomization:

### Properties

```dart
bool randomizeQuestions = false;  // Flag for question randomization
bool randomizeAnswers = false;    // Flag for answer randomization
```

### Usage in `createRoom()`

When a room is created, the `createRoom()` method checks these flags and applies randomization before storing the quiz data:

```dart
Future<void> createRoom(String text) async {
  // ... parse quiz data
  var quizDataTemp = QuizData.fromJson(jsonData);

  // Apply randomization if configured
  if (randomizeQuestions || randomizeAnswers) {
    quizDataTemp = RandomizationService().randomizeQuiz(
      quizData: quizDataTemp,
      randomizeQuestions: randomizeQuestions,
      randomizeAnswers: randomizeAnswers,
    );
  }

  quizData = quizDataTemp;
  // ... continue room creation
}
```

The randomization settings are also stored in Firebase for reference:

```dart
'randomizeQuestions': randomizeQuestions,
'randomizeAnswers': randomizeAnswers,
```

## Admin UI Integration

The `AdminScreen` now includes a "Randomization Options" section with two checkboxes:

1. **Randomize Questions** - Shuffles the order of questions within each section
2. **Randomize Answers** - Shuffles answer options for each question

These options are set before creating a room and are applied automatically during the room creation process.

## Technical Details

### How Answer Randomization Works

When randomizing answers, the service:

1. Creates index pairs `(option_text, original_index)` for each option
2. Shuffles these pairs to create a new random order
3. Extracts the shuffled options in the new order
4. Maps the original "correct answer indices" to their new positions

**Example:**

```
Original: options = ["Paris", "London", "Berlin", "Madrid"]
          correct = [0]  // "Paris" is correct

After shuffle: options = ["Berlin", "Madrid", "Paris", "London"]
               correct = [2]  // "Paris" is now at index 2
```

This ensures that regardless of how options are shuffled, the correct answers remain correctly identified.

### Single vs Multiple Choice

- **Single Choice (type: 'single')**: Works with single correct index
- **Multiple Choice (type: 'multiple')**: Works with multiple correct indices, all of which are properly remapped

## Usage Flow

1. **Admin uploads quiz data** through `AdminScreen`
2. **Admin selects randomization options** (randomize questions, randomize answers, or both)
3. **Admin creates room** - randomization is applied during this step
4. **Randomized quiz is stored** in Firebase with randomization flags
5. **Students see randomized quiz** when they join the room

## Benefits

- **Enhanced Security**: Prevents students from sharing answers across quiz instances
- **Fair Assessment**: Each student potentially sees questions in different orders
- **Consistent Scoring**: Answer randomization is transparent and doesn't affect scoring logic
- **Flexible Configuration**: Admins can choose to randomize questions, answers, both, or neither

## Important Notes

- Randomization is applied **once** when the room is created
- All students in the same room see the **same randomized quiz**
- The randomization is deterministic within a single room creation
- Students joining different rooms with the same quiz data will see different randomizations if enabled
- The service uses Dart's `Random` class for shuffling

## Future Enhancements

Possible future improvements:

- Per-section randomization configuration
- Randomization history tracking
- Different randomization for each student (requires individual quiz generation)
- Randomization templates/presets

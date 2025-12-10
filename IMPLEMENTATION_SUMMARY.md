# Randomization Service - Implementation Summary

## What Was Implemented

A complete randomization feature has been added to your quiz application, allowing administrators to randomize questions and/or answers when creating quiz rooms.

## Files Created/Modified

### New Files

1. **`lib/services/randomization_service.dart`** - The core randomization service
   - Handles question and answer shuffling
   - Manages correct answer index remapping for shuffled options
   - Provides multiple convenience methods

### Modified Files

1. **`lib/services/main_controller.dart`**

   - Added `randomizeQuestions` and `randomizeAnswers` properties
   - Updated `createRoom()` to apply randomization
   - Stores randomization settings in Firebase

2. **`lib/views/admin/admin_screen.dart`**
   - Added randomization options UI with checkboxes
   - Integrated with the randomization service
   - User-friendly interface for admin control

## Quick Start Guide

### For Admins

When creating a quiz room:

1. Upload or paste your quiz JSON data
2. Check the desired randomization options:
   - ✅ **Randomize Questions** - Shuffles question order within sections
   - ✅ **Randomize Answers** - Shuffles answer options for each question
3. Click "Create Room"

The randomization is applied automatically before the room is created.

### For Developers

To use the randomization service programmatically:

```dart
import 'package:quiz_game/services/randomization_service.dart';

// Randomize both questions and answers
final randomized = RandomizationService().randomizeAll(quizData);

// Randomize only questions
final questionsShuffled = RandomizationService().randomizeQuestionsOnly(quizData);

// Randomize only answers
final answersShuffled = RandomizationService().randomizeAnswersOnly(quizData);

// Custom randomization
final custom = RandomizationService().randomizeQuiz(
  quizData: quizData,
  randomizeQuestions: true,
  randomizeAnswers: false,
);
```

## Key Features

✅ **Automatic Correct Answer Tracking**

- When answers are shuffled, the correct answer indices are automatically updated
- No need for manual correction

✅ **Works with All Question Types**

- Single-choice questions
- Multiple-choice questions

✅ **Per-Section Randomization**

- Questions are randomized only within their section
- Sections themselves maintain their order

✅ **Singleton Pattern**

- The service uses a singleton pattern for consistency
- Only one instance exists throughout the application

✅ **Firebase Integration**

- Randomization settings are stored with each room
- Can be referenced for audit trails or analytics

## Example Quiz Data

Before randomization:

```json
{
  "sections": [
    {
      "name": "Math",
      "questions": [
        {
          "question": "What is 2+2?",
          "type": "single",
          "options": ["3", "4", "5"],
          "correct": [1],
          "timeLimit": 30
        },
        {
          "question": "What is 5+5?",
          "type": "single",
          "options": ["10", "15", "20"],
          "correct": [0],
          "timeLimit": 30
        }
      ]
    }
  ]
}
```

After randomization (with both flags enabled):

- Questions might appear in order: 2nd, 1st
- Each question's options are shuffled, with correct indices updated automatically

## Testing the Feature

To test locally:

1. Open the admin screen
2. Paste your quiz JSON
3. Toggle the randomization checkboxes
4. Create the room and verify students see randomized content

## Data Stored in Firebase

When a room is created with randomization:

```json
{
  "code": "ABC123",
  "admin": "user_id",
  "quizData": {
    /* randomized quiz data */
  },
  "randomizeQuestions": true,
  "randomizeAnswers": true,
  "status": "waiting",
  "createdAt": 1234567890
}
```

## Performance Considerations

- Randomization is **applied once** during room creation
- No performance impact on students taking the quiz
- All students in the same room see the **same randomization**
- Uses efficient shuffle algorithm (Fisher-Yates via `List.shuffle()`)

## Future Enhancement Ideas

1. **Per-Student Randomization** - Generate unique randomization for each student
2. **Randomization Templates** - Save and reuse randomization presets
3. **Selective Randomization** - Randomize specific sections only
4. **Analytics** - Track which randomization configurations are most used
5. **Randomization Seed** - Allow reproducible randomization for debugging

## Troubleshooting

**Q: Are correct answers affected by randomization?**
A: No, the service automatically remaps correct answer indices when options are shuffled.

**Q: Do all students see the same randomization?**
A: Yes, randomization is applied once when the room is created, so all students see the same randomized quiz.

**Q: Can I randomize different rooms differently?**
A: Yes, each room is created independently with its own randomization settings.

**Q: What if I don't want randomization?**
A: Simply leave both checkboxes unchecked, and the quiz will be presented as originally provided.

## Architecture Diagram

```
AdminScreen
    ↓
User checks randomization options
    ↓
User creates room
    ↓
MainController.createRoom()
    ↓
RandomizationService.randomizeQuiz()
    ↓
Returns randomized QuizData
    ↓
Stored in Firebase
    ↓
Students receive randomized quiz
```

---

**Created:** December 7, 2025
**Status:** Ready for use

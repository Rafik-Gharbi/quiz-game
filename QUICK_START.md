# Quick Start: Randomization Feature

## Installation

✅ **Already installed!** The randomization feature is fully integrated into your project.

## How to Use

### Step 1: Open Admin Screen

Navigate to the admin screen where you upload quiz data.

### Step 2: Add Your Quiz

- Click "Choose File" to upload a JSON file, or
- Paste your quiz JSON directly into the text area

### Step 3: Select Randomization Options

Check any or all of these options:

- ☑️ **Randomize Questions** - Shuffle question order within sections
- ☑️ **Randomize Answers** - Shuffle answer options

### Step 4: Create Room

Click the "Create Room" button. The quiz will be randomized automatically before the room is created.

### Step 5: Share with Students

Students join the room normally and receive the randomized quiz.

---

## Example Quiz JSON Format

```json
{
  "sections": [
    {
      "name": "Mathematics",
      "questions": [
        {
          "question": "What is the capital of France?",
          "type": "single",
          "options": ["London", "Paris", "Berlin", "Madrid"],
          "correct": [1],
          "timeLimit": 30
        },
        {
          "question": "Select all prime numbers",
          "type": "multiple",
          "options": ["2", "3", "4", "5", "6"],
          "correct": [0, 1, 3],
          "timeLimit": 60
        }
      ]
    }
  ]
}
```

---

## What Gets Randomized?

### With "Randomize Questions" ✓

- Question order changes within each section
- Students see questions in different orders

### With "Randomize Answers" ✓

- Answer option positions are shuffled
- Correct answers are automatically tracked
- Students see options in different orders

### With Both ✓

- Questions appear in different order
- Answers for each question are shuffled
- Complete randomization

### With Neither (default)

- Quiz remains exactly as provided
- All students see identical quiz

---

## Key Features

✅ **Automatic Correct Answer Tracking**
No need to manually fix correct answers - the service handles it automatically.

✅ **Per-Room Randomization**
Each room can have different randomization settings.

✅ **Consistent for All Students**
All students in the same room see the same randomization.

✅ **Supports All Question Types**

- Single choice ✓
- Multiple choice ✓

✅ **Works with Sections**
Questions randomize within sections, not across sections.

---

## Common Questions

**Q: Will correct answers be affected?**
A: No, they're automatically remapped. The correct answer is always correct regardless of position.

**Q: Do I need to modify my quiz JSON?**
A: No, your existing quiz format works perfectly.

**Q: Can I randomize different rooms differently?**
A: Yes! Each room creation is independent.

**Q: What if I don't want randomization?**
A: Leave the checkboxes unchecked when creating the room.

**Q: Can students turn randomization on/off?**
A: No, it's set by the admin when creating the room.

---

## Troubleshooting

**Issue: Checkboxes not showing**

- Make sure you're using the latest code
- Clear app cache and rebuild

**Issue: Randomization not working**

- Verify checkboxes are checked before creating room
- Check browser console for errors

**Issue: Wrong answers marked as correct**

- This shouldn't happen - report as bug if it does
- Service automatically remaps correct indices

---

## Developer Integration

To use in code:

```dart
import 'package:quiz_games/services/randomization_service.dart';

// Randomize everything
var randomized = RandomizationService().randomizeAll(quizData);

// Randomize only questions
var questionsShuffled = RandomizationService()
    .randomizeQuestionsOnly(quizData);

// Randomize only answers
var answersShuffled = RandomizationService()
    .randomizeAnswersOnly(quizData);
```

---

## Files Modified/Created

**New Service:**

- `lib/services/randomization_service.dart` - Core randomization logic

**Modified:**

- `lib/services/main_controller.dart` - Integration with room creation
- `lib/views/admin/admin_screen.dart` - UI for randomization options

**Documentation:**

- `RANDOMIZATION_FEATURE.md` - Comprehensive documentation
- `IMPLEMENTATION_SUMMARY.md` - Implementation details
- `API_REFERENCE.md` - Complete API documentation
- `test/services/randomization_service_test.dart` - Unit test examples

---

## Next Steps

1. **Test it out** - Create a test quiz and try randomization options
2. **Deploy** - Push changes to production when ready
3. **Monitor** - Track usage and gather feedback from students
4. **Enhance** - Consider future improvements (per-student randomization, etc.)

---

**Ready to use!** No additional setup required. 🚀

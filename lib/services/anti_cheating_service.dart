import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show Durations;
import 'package:quiz_games/models/question.dart';
import 'package:quiz_games/services/main_controller.dart';
import 'package:quiz_games/views/widgets/fullscreen_dialog.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:get/get.dart';

@JS()
@staticInterop
class Screen {}

extension ScreenProps on Screen {
  external int get width;
  external int get height;
}

@JS('window.screen')
external Screen get jsScreen;

class AntiCheatingService extends GetxController {
  static bool disabled = false; // set to true to disable

  static AntiCheatingService get find => Get.find<AntiCheatingService>();

  // Timers and intervals
  Timer? _fullscreenCheckTimer;
  int? _devToolsCheckIntervalId;

  // Visibility subscriptions
  StreamSubscription? _visibilitySubscription;
  StreamSubscription? _keyboardSubscription;

  bool checkForFullscreenExit = false;
  Map<int, Set<String>> detectedCheatings =
      {}; // Changed from List to Set for deduplication
  DateTime? startedQuestionTime;

  // Rate limiting for duplicate events
  final Map<String, DateTime> _lastReportedEvents = {};
  static const Duration _reportCooldown = Duration(seconds: 2);

  @override
  void dispose() {
    _fullscreenCheckTimer?.cancel();
    _visibilitySubscription?.cancel();
    _keyboardSubscription?.cancel();
    _clearDevToolsInterval();
    super.dispose();
  }

  AntiCheatingService() {
    if (disabled == true) return;
    _setupVisibilityDetection();
    _setupFullscreenDetection();
    _setupKeyboardDetection();
    _setupContextMenuBlock();
    _setupActivityTracking();
    _setupBlurFocusDetection();
  }

  /// Rate-limited event reporting to prevent duplicate spam
  bool _shouldReportEvent(String eventType) {
    final lastReport = _lastReportedEvents[eventType];
    if (lastReport == null) {
      _lastReportedEvents[eventType] = DateTime.now();
      return true;
    }

    if (DateTime.now().difference(lastReport) > _reportCooldown) {
      _lastReportedEvents[eventType] = DateTime.now();
      return true;
    }
    return false;
  }

  Future<void> reportEventToServer(String type) async {
    // Rate limiting - prevent spam reporting
    if (!_shouldReportEvent(type)) return;

    final cheatingDetectedType = 'Cheating Detected: $type';
    debugPrint(cheatingDetectedType);
    final inProgress =
        MainController.find.studentData?.status == 'active' ||
        Get.currentRoute == "/StudentQuizScreen";
    if (!inProgress) return;

    final questionIndex = MainController.find.indexFromTotalQuestions == 0
        ? 1
        : MainController.find.indexFromTotalQuestions;
    final existQuestion = detectedCheatings.containsKey(questionIndex);

    if (existQuestion) {
      detectedCheatings[questionIndex]!.add(type);
    } else {
      detectedCheatings[questionIndex] = {type};
    }
    debugPrint('Reported $cheatingDetectedType for question $questionIndex');
  }

  void checkFullscreenEnabled({bool force = false}) {
    final inProgress = Get.currentRoute == "/StudentQuizScreen";
    if (!inProgress && !force) return;
    if ((checkForFullscreenExit || force) &&
        web.document.fullscreenElement == null &&
        Get.isDialogOpen != true) {
      if (!force) reportEventToServer("fullscreen_exit");
      _openFullscreenRequiredDialog(force: force);
    }
  }

  void checkQuestionTime(Question question) {
    if (startedQuestionTime == null) return;
    final duration = DateTime.now().difference(startedQuestionTime!);
    if (duration.inMinutes > question.timeLimit) {
      reportEventToServer(
        "question_time_exceeded_${duration.inMinutes - question.timeLimit}mn",
      );
    }
    // Only reset after reporting to avoid race conditions
    startedQuestionTime = null;
  }

  void _setupVisibilityDetection() {
    _visibilitySubscription = web.document.onVisibilityChange.listen((event) {
      final isHidden = web.document.hidden;
      if (isHidden == true) {
        reportEventToServer("tab_switched");
      }
    });
  }

  void _setupFullscreenDetection() {
    web.document.addEventListener(
      'fullscreenchange',
      ((web.Event event) => checkFullscreenEnabled()).toJS,
    );
  }

  void _setupKeyboardDetection() {
    _keyboardSubscription = web.window.onKeyDown.listen((event) {
      final keyboardEvent = event;

      if (keyboardEvent.key == "PrintScreen") {
        reportEventToServer("screenshot_key");
        event.preventDefault();
      }

      if (keyboardEvent.ctrlKey == true && keyboardEvent.key == "c") {
        reportEventToServer("copy_attempt");
        event.preventDefault();
      }
    });
  }

  void _setupContextMenuBlock() {
    web.document.addEventListener(
      'contextmenu',
      ((web.Event event) {
        (event).preventDefault();
      }).toJS,
    );
  }

  bool _isDevToolsLikelyOpen() {
    bool result = false;
    final outerWidth = web.window.outerWidth;
    final innerWidth = web.window.innerWidth;

    final outerHeight = web.window.outerHeight;
    final innerHeight = web.window.innerHeight;

    // Increased threshold from 160px to 250px to reduce false positives
    const int threshold = 250;

    if ((outerWidth - innerWidth) > threshold) result = true;

    if ((outerHeight - innerHeight) > threshold) result = true;

    if (result) {
      Future.delayed(Duration(seconds: 1), () => checkFullscreenEnabled());
    }

    return result;
  }

  void _clearDevToolsInterval() {
    if (_devToolsCheckIntervalId != null) {
      web.window.clearInterval(_devToolsCheckIntervalId!);
      _devToolsCheckIntervalId = null;
    }
  }

  void _setupActivityTracking() {
    // Store interval ID for proper cleanup
    _devToolsCheckIntervalId = web.window.setInterval(
      (() {
        if (_isDevToolsLikelyOpen()) {
          reportEventToServer("devtools_open");
        }
      }).toJS,
      1000 as JSAny?,
    );
  }

  void _setupBlurFocusDetection() {
    // Detect when window loses focus using document visibility change
    web.document.addEventListener(
      'visibilitychange',
      ((web.Event event) {
        if (web.document.hidden == false) {
          reportEventToServer("window_focus_regained");
        }
      }).toJS,
    );
  }

  void _openFullscreenRequiredDialog({bool force = false}) {
    checkForFullscreenExit = true;
    if (Get.isDialogOpen == true || web.document.fullscreenElement != null) {
      return;
    }
    if (force) {
      _enterFullscreen();
    } else {
      Future.delayed(Durations.extralong4, () {
        // Fixed: Actually call the dialog instead of returning empty map
        if (Get.isDialogOpen != true) {
          FullscreenDialog(() => _enterFullscreen());
        }
      });
    }
  }

  Future<void> _enterFullscreen() async {
    checkForFullscreenExit = true;
    // Cancel previous timer before creating a new one
    _fullscreenCheckTimer?.cancel();
    _fullscreenCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkFullscreenEnabled(),
    );
    if (web.document.fullscreen) return;
    try {
      await web.document.documentElement?.requestFullscreen().toDart;
    } catch (e) {
      debugPrint('Error entering fullscreen: $e');
    }
  }
}

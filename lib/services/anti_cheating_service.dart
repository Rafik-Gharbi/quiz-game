import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show Durations;
import 'package:quiz_game/models/question.dart';
import 'package:quiz_game/services/main_controller.dart';
import 'package:quiz_game/views/widgets/fullscreen_dialog.dart';
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

// JS interop for iOS-specific detections
@JS('window.navigator.mediaDevices')
external JSAny? get mediaDevices;

@JS('window.navigator.permissions')
external JSAny? get permissions;

@JS('window.screen.orientation')
external JSAny? get screenOrientation;

@JS('navigator.clipboard')
external JSAny? get clipboard;

class AntiCheatingService extends GetxController {
  static bool disabled = false; // set to true to disable

  static AntiCheatingService get find => Get.find<AntiCheatingService>();

  // Timers and intervals
  Timer? _fullscreenCheckTimer;
  int? _devToolsCheckIntervalId;
  Timer? _inactivityTimer;

  // Visibility subscriptions
  StreamSubscription? _visibilitySubscription;
  StreamSubscription? _keyboardSubscription;
  StreamSubscription? _pageVisibilitySubscription;

  // iOS-specific tracking
  // DateTime? _lastUserActivityTime;
  // double? _lastOrientation;
  // Set<String> _activeMediaStreams = {};
  // static const Duration _inactivityThreshold = Duration(seconds: 30);

  bool checkForFullscreenExit = false;
  Map<int, Set<String>> detectedCheatings =
      {}; // Changed from List to Set for deduplication
  DateTime? startedQuestionTime;
  int? _questionStartTimeMs; // Track milliseconds for precise time verification

  // Rate limiting for duplicate events
  final Map<String, DateTime> _lastReportedEvents = {};
  static const Duration _reportCooldown = Duration(seconds: 2);

  @override
  void dispose() {
    _fullscreenCheckTimer?.cancel();
    _inactivityTimer?.cancel();
    _visibilitySubscription?.cancel();
    _keyboardSubscription?.cancel();
    _pageVisibilitySubscription?.cancel();
    _clearDevToolsInterval();
    // _cleanupMediaStreams();
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
    _setupIOSFriendlyDetections();
    _setupPageVisibilityDetection();
    // _setupMediaStreamDetection();
    // _setupOrientationDetection();
    // _setupScreenRecordingDetection();
    _setupClipboardAccessDetection();
    // _setupInactivityDetection();
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
        // !Helper.isMobile() &&
        !GetPlatform.isIOS &&
        Get.isDialogOpen != true) {
      if (!force) reportEventToServer("fullscreen_exit");
      _openFullscreenRequiredDialog(force: force);
    }
  }

  void checkQuestionTime(Question question) {
    if (startedQuestionTime == null || _questionStartTimeMs == null) return;

    final elapsedMs =
        DateTime.now().millisecondsSinceEpoch - _questionStartTimeMs!;
    final elapsedSeconds = (elapsedMs / 1000).floor();
    final timeLimitSeconds = question.timeLimit;

    // Verify actual time spent matches expected time
    // If time elapsed is significantly less than expected, app was backgrounded
    if (elapsedSeconds > timeLimitSeconds) {
      final excessSeconds = elapsedSeconds - timeLimitSeconds;
      reportEventToServer(
        "question_time_exceeded_${(excessSeconds / 60).floor()}mn",
      );
    }

    // Check if actual elapsed time indicates app backgrounding
    // (user took much less time than UI timer showed)
    debugPrint(
      'Question elapsed time: ${elapsedSeconds}s, limit: ${timeLimitSeconds}s',
    );

    // Only reset after reporting to avoid race conditions
    startedQuestionTime = null;
    _questionStartTimeMs = null;
  }

  /// Start tracking time for a new question (iOS timer verification)
  void startQuestionTimer(Question question) {
    startedQuestionTime = DateTime.now();
    _questionStartTimeMs = DateTime.now().millisecondsSinceEpoch;
    debugPrint('Started tracking question at $_questionStartTimeMs');
  }

  /// Verify if user spent suspicious time away from app during question
  bool verifyQuestionTimeIntegrity(Question question) {
    if (startedQuestionTime == null || _questionStartTimeMs == null) {
      return true; // Can't verify, allow
    }

    final elapsedMs =
        DateTime.now().millisecondsSinceEpoch - _questionStartTimeMs!;
    final elapsedSeconds = (elapsedMs / 1000).floor();
    final timeLimitSeconds = question.timeLimit * 60;

    // If time exceeded, it's suspicious
    if (elapsedSeconds > timeLimitSeconds) {
      return false;
    }

    return true;
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
      1000.toJS,
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

  /// Enhanced iOS visibility detection (more reliable than tab_switched)
  void _setupPageVisibilityDetection() {
    _pageVisibilitySubscription = web.document.onVisibilityChange.listen((
      event,
    ) {
      final isHidden = web.document.hidden;
      if (isHidden == true) {
        // _recordUserActivity();
        reportEventToServer("app_backgrounded");
      } else {
        // _recordUserActivity();
        reportEventToServer("app_foregrounded");
      }
    });
  }

  /// iOS-specific enhanced detections
  void _setupIOSFriendlyDetections() {
    // Focus/Blur events for better iOS WebView detection
    web.document.addEventListener(
      'focus',
      ((web.Event event) {
        // _recordUserActivity();
        debugPrint('Window focused');
      }).toJS,
    );

    web.document.addEventListener(
      'blur',
      ((web.Event event) {
        debugPrint('Window blurred - possible tab switch or app switch');
        reportEventToServer("window_blur_detected");
      }).toJS,
    );
  }

  /// Detect media stream access (camera/microphone)
  // void _setupMediaStreamDetection() {
  //   try {
  //     // Try to access getUserMedia to monitor for camera/mic access attempts
  //     debugPrint('Media stream detection setup initialized');
  //     // Note: Media stream detection via JS interop requires careful handling
  //     // on iOS Safari due to security restrictions
  //   } catch (e) {
  //     debugPrint('Could not setup media stream detection: $e');
  //   }
  // }

  /// Detect screen orientation changes (iPad user trying to cheat by rotating)
  // void _setupOrientationDetection() {
  //   try {
  //     web.window.addEventListener(
  //       'orientationchange',
  //       ((web.Event event) {
  //         final orientation = web.window.innerHeight > web.window.innerWidth
  //             ? 0
  //             : 90;
  //         if (_lastOrientation != null && _lastOrientation != orientation) {
  //           reportEventToServer("device_rotated");
  //         }
  //         _lastOrientation = orientation.toDouble();
  //       }).toJS,
  //     );
  //   } catch (e) {
  //     debugPrint('Could not setup orientation detection: $e');
  //   }
  // }

  /// Detect screen recording (iOS 14+)
  // void _setupScreenRecordingDetection() {
  //   try {
  //     debugPrint('Screen recording detection setup initialized');
  //     // Note: Screen recording detection requires special permissions on iOS
  //     // This setup monitors for suspicious media device enumeration
  //   } catch (e) {
  //     debugPrint('Could not setup screen recording detection: $e');
  //   }
  // }

  /// Detect clipboard access (copy/paste attempts)
  void _setupClipboardAccessDetection() {
    try {
      web.document.addEventListener(
        'copy',
        ((web.Event event) {
          reportEventToServer("clipboard_copy");
          event.preventDefault();
        }).toJS,
      );

      web.document.addEventListener(
        'paste',
        ((web.Event event) {
          reportEventToServer("clipboard_paste");
          event.preventDefault();
        }).toJS,
      );
    } catch (e) {
      debugPrint('Could not setup clipboard detection: $e');
    }
  }

  /// Detect user inactivity (might indicate device left unattended)
  // void _setupInactivityDetection() {
  //   _recordUserActivity();
  //   _inactivityTimer = Timer.periodic(Duration(seconds: 5), (_) {
  //     final inProgress =
  //         MainController.find.studentData?.status == 'active' ||
  //         Get.currentRoute == "/StudentQuizScreen";
  //     if (!inProgress) return;

  //     if (_lastUserActivityTime != null) {
  //       final inactivityDuration = DateTime.now().difference(
  //         _lastUserActivityTime!,
  //       );
  //       if (inactivityDuration.inSeconds > 30 &&
  //           inactivityDuration > _inactivityThreshold) {
  //         reportEventToServer(
  //           "user_inactive_${(inactivityDuration.inSeconds / 60).floor()}s",
  //         );
  //       }
  //     }
  //   });
  // }

  // void _recordUserActivity() {
  //   _lastUserActivityTime = DateTime.now();
  // }

  // void _cleanupMediaStreams() {
  //   for (final stream in _activeMediaStreams) {
  //     try {
  //       debugPrint('Stopping media stream: $stream');
  //     } catch (e) {
  //       debugPrint('Error cleaning up media stream: $e');
  //     }
  //   }
  //   _activeMediaStreams.clear();
  // }

  /// Lock device to landscape orientation for iOS
  // Future<void> lockToLandscape() async {
  //   try {
  //     debugPrint('Attempting to lock orientation to landscape');
  //     // Note: iOS Safari has limited support for screen orientation locking
  //     // This is primarily a hint to the system
  //   } catch (e) {
  //     debugPrint('Could not lock orientation: $e');
  //   }
  // }

  /// Unlock device orientation
  // Future<void> unlockOrientation() async {
  //   try {
  //     debugPrint('Unlocking device orientation');
  //     // Note: Restoring normal orientation behavior
  //   } catch (e) {
  //     debugPrint('Could not unlock orientation: $e');
  //   }
  // }

  /// Get current device information for iOS detection
  Map<String, dynamic> getDeviceInfo() {
    return {
      'userAgent': web.window.navigator.userAgent,
      'isIOS':
          web.window.navigator.userAgent.toLowerCase().contains('iphone') ||
          web.window.navigator.userAgent.toLowerCase().contains('ipad'),
      'isSafari':
          web.window.navigator.userAgent.toLowerCase().contains('safari') &&
          !web.window.navigator.userAgent.toLowerCase().contains('chrome'),
      'screenWidth': web.window.screen.width,
      'screenHeight': web.window.screen.height,
      'devicePixelRatio': web.window.devicePixelRatio,
    };
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

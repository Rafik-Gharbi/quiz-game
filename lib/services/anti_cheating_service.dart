import 'dart:async';

import 'package:flutter/material.dart' show Durations;
import 'package:quiz_games/models/question.dart';
import 'package:quiz_games/services/main_controller.dart';
import 'package:quiz_games/utils/helper.dart';
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
  static AntiCheatingService find = Get.find<AntiCheatingService>();
  static bool disabled = false; // set to true to disable
  // DateTime _lastActivity = DateTime.now();
  Timer? timer;
  bool checkForFullscreenExit = false;
  Map<int, List<String>> detectedCheatings = {};
  DateTime? startedQuestionTime;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  AntiCheatingService() {
    if (disabled == true) return;
    _setupVisibilityDetection();
    _setupFullscreenDetection();
    _setupKeyboardDetection();
    _setupContextMenuBlock();
    _setupActivityTracking();
  }

  Future<void> reportEventToServer(String type) async {
    final cheatingDetectedType = 'Cheating Detected: $type';
    print(cheatingDetectedType);
    Helper.snackBar(
      message: cheatingDetectedType,
      duration: Durations.extralong4,
    );
    final inProgress =
        MainController.find.studentData?.status == 'active' ||
        Get.currentRoute == "/StudentQuizScreen";
    print('status ${MainController.find.studentData?.status}');
    print('inProgress $inProgress');
    if (!inProgress) return;
    final existQuestion = detectedCheatings.containsKey(
      MainController.find.indexFromTotalQuestions,
    );
    if (existQuestion) {
      detectedCheatings[MainController.find.indexFromTotalQuestions]!.add(type);
    } else {
      detectedCheatings[MainController.find.indexFromTotalQuestions] = [type];
    }
    print('Reported $cheatingDetectedType');
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
    startedQuestionTime = null;
  }

  void _setupVisibilityDetection() {
    web.document.onVisibilityChange.listen((event) {
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
    web.window.onKeyDown.listen((event) {
      final keyboardEvent = event;

      if (keyboardEvent.key == "PrintScreen") {
        reportEventToServer("screenshot_key");
      }

      if (keyboardEvent.ctrlKey == true && keyboardEvent.key == "c") {
        reportEventToServer("copy_attempt");
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

    if ((outerWidth - innerWidth) > 160) result = true;

    if ((outerHeight - innerHeight) > 160) result = true;

    if (result) {
      Future.delayed(Duration(seconds: 1), () => checkFullscreenEnabled());
    }

    return result;
  }

  void _setupActivityTracking() {
    web.window.setInterval(
      (() {
        if (_isDevToolsLikelyOpen()) {
          reportEventToServer("devtools_open");
        }
      }).toJS,
      null,
      1000,
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
      Future.delayed(
        Durations.extralong4,
        () => Get.isDialogOpen == true
            ? {}
            : FullscreenDialog(() => _enterFullscreen()),
      );
    }
  }

  Future<void> _enterFullscreen() async {
    checkForFullscreenExit = true;
    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkFullscreenEnabled(),
    );
    if (web.document.fullscreen) return;
    await web.document.documentElement?.requestFullscreen().toDart;
  }

  bool _isFullscreen() {
    final elem = web.document.fullscreenElement;

    final heightMatch =
        (web.window.innerHeight.toDouble() >= jsScreen.height.toDouble() - 5);

    final widthMatch =
        (web.window.innerWidth.toDouble() >= jsScreen.width.toDouble() - 5);

    return elem != null || (heightMatch && widthMatch);
  }
}

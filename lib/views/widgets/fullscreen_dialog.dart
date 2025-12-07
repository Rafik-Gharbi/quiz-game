import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FullscreenDialog {
  final void Function() onFullscreen;
  FullscreenDialog(this.onFullscreen) {
    Get.dialog(buildAlert(), barrierDismissible: false);
  }

  AlertDialog buildAlert() => AlertDialog(
    title: Text("Warning"),
    content: Text("Please enable fullscreen mode to continue the quiz."),
    actions: [
      TextButton(
        onPressed: () {
          onFullscreen();
          Get.back();
        },
        child: Text("OK"),
      ),
    ],
  );
}

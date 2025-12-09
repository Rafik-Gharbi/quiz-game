import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../services/theme/theme.dart';
import 'constants/colors.dart';
import 'constants/constants.dart';

class Helper {
  static bool get isArabic => Get.locale?.languageCode == 'ar';

  static Future<dynamic> waitAndExecute(
    bool Function() condition,
    Function callback, {
    Duration? duration,
  }) async {
    while (!condition()) {
      await Future.delayed(
        duration ?? const Duration(milliseconds: 800),
        () {},
      );
    }
    return callback();
  }

  static bool isMobile() =>
      // kIsWeb && ResponsiveBreakpoints.of(Get.context!).isMobile ||
      (kIsWeb && Get.width <= kMobileMaxWidth) ||
      GetPlatform.isAndroid ||
      GetPlatform.isIOS ||
      GetPlatform.isMobile;

  static void snackBar({
    String message = 'Snack bar test',
    String? title,
    Duration? duration,
    bool includeDismiss = true,
    Widget? overrideButton,
    TextStyle? styleMessage,
  }) {
    const minSnackBarWidth = 400;
    double marginLeft = Get.width - 50 - minSnackBarWidth;
    if (marginLeft < 0) marginLeft = 50;
    GetSnackBar(
      titleText: title != null
          ? Text(title.tr, style: styleMessage ?? AppFonts.x16Bold)
          : null,
      messageText: Text(message.tr, style: styleMessage ?? AppFonts.x14Regular),
      duration: duration ?? const Duration(seconds: 3),
      isDismissible: true,
      borderColor: kSecondaryColor,
      borderWidth: 2,
      borderRadius: 10,
      margin: isMobile()
          ? const EdgeInsets.symmetric(horizontal: 2)
          : resolvePadding(left: marginLeft, right: 50, bottom: 10),
      backgroundColor: kNeutralColor100,
      snackPosition: SnackPosition.BOTTOM,
      mainButton:
          overrideButton ??
          (includeDismiss
              ? TextButton(
                  onPressed: () => Get.closeAllSnackbars(),
                  child: Text('dismiss'.tr),
                )
              : null),
    ).show();
  }

  static EdgeInsets resolvePadding({
    double? right,
    double? left,
    double? bottom,
    double? top,
  }) => EdgeInsets.only(
    left: isArabic ? right ?? 0 : left ?? 0,
    right: isArabic ? left ?? 0 : right ?? 0,
  ).copyWith(top: top, bottom: bottom);

  static String joinedTime(joinedAt) {
    final date = DateTime.fromMillisecondsSinceEpoch(joinedAt);
    final formatted = DateFormat('HH:mm:ss').format(date);
    return formatted;
  }
}

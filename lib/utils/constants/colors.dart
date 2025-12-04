import 'package:flutter/material.dart';

/// This file contains the color constants used in the application.
/// It includes the primary, secondary, accent, error, and other colors.
/// Change and add colors as needed.

const Color kPrimaryColor = Color(
  0xFF5B7FFF,
); // Color.fromARGB(255, 231, 163, 61);
// Color.fromARGB(255, 231, 163, 61); // Color.fromARGB(255, 235, 188, 106); // Color(0xFFFF5B04); // Colors.orange; // Color.fromARGB(255, 63, 113, 240);
const Color kSecondaryColor = Color.fromARGB(255, 38, 47, 64);
const Color kAccentColor = Color(0xFFEACB6E);
const Color kErrorColor = Color(0xFFE21200);
const Color kRatingColor = Color(0xFFFDCC0D);
const Color kNeutralColor = Color(0xFF888888);
const Color kNeutralDarkColor = Color.fromARGB(255, 17, 45, 62);
const Color kNeutralLightColor = Color(0xFFEEEEEE);
const Color kBlackColor = Colors.black;
const Color kBGDarkColor = Color.fromARGB(255, 7, 12, 16);
const Color kNeutralColor100 = Colors.white;
const Color kDisabledColor = Colors.grey;
const Color kConfirmedColor = Color(0xFF34A853);
const Color kSelectedDarkColor = Color.fromARGB(255, 0, 114, 208);
const Color kSelectedColor = Color(0xff008BF9);

Color get kNeutralOpacityColor => kNeutralColor.withAlpha(178);
Color get kNeutralLightOpacityColor => kNeutralLightColor.withAlpha(178);

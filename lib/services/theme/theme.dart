import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

enum MyThemeMode { light, dark }

/// This class is for centralizing the app text styles.
/// It provides a consistent way to define and use text styles throughout the app.
/// To use it: Text('This is an example text', style: AppFonts.x16Bold)
/// Change the font family and add more styles as needed.
class AppFonts {
  static const String _fontFamily = 'Outfit';

  static TextStyle get x40Bold => TextStyle(fontFamily: _fontFamily, color: kBlackColor, fontSize: Sizes.x40, fontWeight: FontWeight.bold);
  static TextStyle get x28Regular => TextStyle(fontFamily: _fontFamily, color: kBlackColor, fontSize: Sizes.x28);
  static TextStyle get x28Bold => TextStyle(color: kBlackColor, fontFamily: _fontFamily, fontSize: Sizes.x28, fontWeight: FontWeight.bold);
  static TextStyle get x24Bold => TextStyle(color: kBlackColor, fontFamily: _fontFamily, fontSize: Sizes.x24, fontWeight: FontWeight.bold);
  static TextStyle get x20Bold => TextStyle(color: kBlackColor, fontFamily: _fontFamily, fontSize: Sizes.x20, fontWeight: FontWeight.bold);
  static TextStyle get x20Regular => TextStyle(color: kBlackColor, fontFamily: _fontFamily, fontSize: Sizes.x20);
  static TextStyle get x18Bold => TextStyle(color: kBlackColor, fontFamily: _fontFamily, fontSize: Sizes.x18, fontWeight: FontWeight.bold);
  static TextStyle get x18Regular => TextStyle(fontFamily: _fontFamily, color: kBlackColor, fontSize: Sizes.x18);
  static TextStyle get x16Bold => TextStyle(fontFamily: _fontFamily, color: kBlackColor, fontSize: Sizes.x16, fontWeight: FontWeight.bold);
  static TextStyle get x16Regular => TextStyle(fontFamily: _fontFamily, color: kBlackColor, fontSize: Sizes.x16);
  static TextStyle get x15Bold => TextStyle(fontFamily: _fontFamily, color: kBlackColor, fontSize: Sizes.x15, fontWeight: FontWeight.bold);
  static TextStyle get x14Bold => TextStyle(fontFamily: _fontFamily, color: kBlackColor, fontSize: Sizes.x14, fontWeight: FontWeight.bold);
  static TextStyle get x14Regular => TextStyle(fontFamily: _fontFamily, color: kBlackColor, fontSize: Sizes.x14);
  static TextStyle get x13Regular => TextStyle(fontFamily: _fontFamily, color: kBlackColor, fontSize: Sizes.x13);
  static TextStyle get x12Bold => TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: kBlackColor, fontSize: Sizes.x12);
  static TextStyle get x12Regular => TextStyle(fontFamily: _fontFamily, color: kBlackColor, fontSize: Sizes.x12);
  static TextStyle get x11Bold => TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: kBlackColor, fontSize: Sizes.x11);
  static TextStyle get x10Bold => TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: kBlackColor, fontSize: Sizes.x10);
  static TextStyle get x10Regular => TextStyle(fontFamily: _fontFamily, color: kBlackColor, fontSize: Sizes.x10);

  ThemeData basicTheme({MyThemeMode theme = MyThemeMode.light}) {
    final ThemeData lightBase = ThemeData.light();
    final ThemeData darkBase = ThemeData.dark();

    TextTheme basicTextTheme(TextTheme base) => base.copyWith(displayLarge: AppFonts.x18Bold);

    if (theme == MyThemeMode.light) {
      return lightBase.copyWith(
        textTheme: basicTextTheme(lightBase.textTheme),
        brightness: Brightness.light,
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kNeutralColor100,
        appBarTheme: AppBarTheme(backgroundColor: kNeutralColor100),
        bottomSheetTheme: BottomSheetThemeData(surfaceTintColor: Colors.transparent, dragHandleColor: kNeutralColor, backgroundColor: kNeutralColor100),
        scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStatePropertyAll(kNeutralColor)),
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: kPrimaryColor,
          onPrimary: Color.alphaBlend(kPrimaryColor, kNeutralColor.withAlpha(50)),
          secondary: kAccentColor,
          onSecondary: Color.alphaBlend(kAccentColor, kNeutralColor.withAlpha(50)),
          error: kErrorColor,
          onError: Color.alphaBlend(kErrorColor, kNeutralColor.withAlpha(50)),
          surface: kBlackColor,
          onSurface: Color.alphaBlend(kBlackColor, kNeutralColor.withAlpha(50)),
        ),
      );
    } else if (theme == MyThemeMode.dark) {
      return darkBase.copyWith(
        textTheme: basicTextTheme(darkBase.textTheme),
        brightness: Brightness.dark,
        iconTheme: IconThemeData(color: kBlackColor),
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kNeutralColor100,
        appBarTheme: AppBarTheme(backgroundColor: kNeutralColor100),
      );
    }
    return ThemeData.light(); //default Flutter theme
  }
}

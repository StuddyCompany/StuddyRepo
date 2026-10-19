import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF253C78);
  static const Color blue = Color(0xFF2B59C3);
  static const Color pink = Color(0xFFF6799A);
  static const Color white = Color(0xFFFFFFFF);

  static const Color fieldFill = Color(0x402B59C3);
  static const Color navy50 = Color(0x80253C78);
  static const Color blue50 = Color(0x802B59C3);

  static const Color background = Color(0xFFF3F6FF);
  static const Color heading = Color(0xFF22386E);
  static const Color lessonCard = Color(0xFF92AAE0);
  static const Color chip = Color(0xFF95ACE1);
  static const Color gray = Color(0xFF6B7280);
  static const Color white90 = Color(0xE6FFFFFF);
  static const Color cardShadow = Color(0x29253C78);
  static const Color softShadow = Color(0x0D000000);
  static const Color pink50 = Color(0x80F6799A);

  static const Color softBlue = Color(0xFFD4E1FF);
  static const Color grayText = Color(0xFF989898);

  static const Color divider = Color(0xFFD9D9D9);
  static const Color lessonTitle = Color(0xFF082561);
  static const Color selectedDay = Color(0xFFC1CFF0);
}

class AppText {
  AppText._();

  static const String fontFamily = 'FuturaMdBT';

  static TextStyle _style(double size, Color color, {double? height}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      fontSize: size,
      letterSpacing: -size * 0.05,
      height: height,
      color: color,
    );
  }

  static TextStyle custom(double size, Color color) => _style(size, color);

  static TextStyle bold(double size, Color color) =>
      _style(size, color).copyWith(fontWeight: FontWeight.w700);

  static final TextStyle heading = bold(24, AppColors.navy);

  static final TextStyle logo =
      _style(96, AppColors.pink).copyWith(letterSpacing: -6.72);
  static final TextStyle hero = _style(64, AppColors.white);
  static final TextStyle heroSubtitle = _style(24, AppColors.white);
  static final TextStyle title = _style(40, AppColors.navy);
  static final TextStyle screenTitle =
      _style(32, AppColors.navy, height: 30 / 32);
  static final TextStyle screenHeader = bold(24, AppColors.white);
  static final TextStyle section = _style(20, AppColors.heading, height: 1.4);
  static final TextStyle field = _style(20, AppColors.navy);
  static final TextStyle button = _style(20, AppColors.white);
  static final TextStyle body = _style(16, AppColors.navy);
  static final TextStyle caption = _style(10, AppColors.navy);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: AppText.fontFamily,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
    scaffoldBackgroundColor: AppColors.white,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.navy,
      selectionColor: AppColors.fieldFill,
      selectionHandleColor: AppColors.navy,
    ),
  );
}

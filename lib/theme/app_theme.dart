import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF253C78); // фон, заголовки, кнопки
  static const Color blue = Color(0xFF2B59C3); // пятна шума в шапке
  static const Color pink = Color(0xFFF6799A); // логотип, активные иконки
  static const Color white = Color(0xFFFFFFFF);

  static const Color fieldFill = Color(0x402B59C3); // #2B59C3, 25% — заливка полей
  static const Color navy50 = Color(0x80253C78); // плейсхолдеры полей
  static const Color blue50 = Color(0x802B59C3); // «Нет аккаунта?»
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

  static final TextStyle logo =
      _style(96, AppColors.pink).copyWith(letterSpacing: -6.72); // «Studdy», трекинг −7%
  static final TextStyle hero = _style(64, AppColors.white); // «Привет!»
  static final TextStyle heroSubtitle = _style(24, AppColors.white);
  static final TextStyle title = _style(40, AppColors.navy); // «Вход», «Регистрация»
  static final TextStyle screenTitle =
      _style(32, AppColors.navy, height: 30 / 32); // «Заполните информацию о себе»
  static final TextStyle field = _style(20, AppColors.navy);
  static final TextStyle button = _style(20, AppColors.white);
  static final TextStyle body = _style(16, AppColors.navy); // ссылки, «< Назад»
  static final TextStyle caption = _style(10, AppColors.navy); // «Заполните поле»
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
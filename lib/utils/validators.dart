class Validators {
  Validators._();

  static const String fillField = 'Заполните поле';
  static final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String value) =>
      value.trim().isEmpty ? fillField : null;

  static String? email(String value) {
    final v = value.trim();
    if (v.isEmpty) return fillField;
    if (!_emailRe.hasMatch(v)) return 'Некорректная почта';
    return null;
  }

  static String? newPassword(String value) {
    if (value.isEmpty) return fillField;
    if (value.length < 6) return 'Минимум 6 символов';
    return null;
  }

  static String? confirmPassword(String value, String original) {
    if (value.isEmpty) return fillField;
    if (value != original) return 'Пароли не совпадают';
    return null;
  }

  /// В БД: CHECK (course >= 1 AND course <= 10)
  static String? course(String value) {
    final v = value.trim();
    if (v.isEmpty) return fillField;
    final n = int.tryParse(v);
    if (n == null || n < 1 || n > 10) return 'Курс от 1 до 10';
    return null;
  }
}

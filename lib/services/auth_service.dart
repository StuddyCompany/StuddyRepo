import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _db = Supabase.instance.client;

  static const String emailTakenMessage =
      'Пользователь с такой почтой уже есть';
  static const String resetRedirectUrl = 'io.supabase.studdy://reset-callback';

  String? lastError;

  User? get currentUser => _db.auth.currentUser;

  bool get isLoggedIn => _db.auth.currentSession != null;

  Future<bool> signIn(String email, String password) async {
    lastError = null;
    try {
      await _db.auth.signInWithPassword(email: email, password: password);
      return true;
    } on AuthException catch (e) {
      debugPrint('signIn error: ${e.message}');
      lastError = _translate(e.message);
      return false;
    } catch (e) {
      debugPrint('signIn error: $e');
      lastError = 'Нет связи с сервером';
      return false;
    }
  }

  Future<bool?> signUp(String email, String password, String firstName) async {
    lastError = null;
    try {
      final res = await _db.auth.signUp(
        email: email,
        password: password,
        data: {'first_name': firstName},
      );

      final identities = res.user?.identities;
      if (res.user != null && identities != null && identities.isEmpty) {
        lastError = emailTakenMessage;
        return null;
      }

      return res.session != null;
    } on AuthException catch (e) {
      debugPrint('signUp error: ${e.message}');
      lastError = _translate(e.message);
      return null;
    } catch (e) {
      debugPrint('signUp error: $e');
      lastError = 'Нет связи с сервером';
      return null;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    lastError = null;
    try {
      await _db.auth.resetPasswordForEmail(email, redirectTo: resetRedirectUrl);
      return true;
    } on AuthException catch (e) {
      debugPrint('sendPasswordReset error: ${e.message}');
      lastError = _translate(e.message);
      return false;
    } catch (e) {
      debugPrint('sendPasswordReset error: $e');
      lastError = 'Не удалось отправить письмо';
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    lastError = null;
    try {
      await _db.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } on AuthException catch (e) {
      debugPrint('updatePassword error: ${e.message}');
      lastError = _translate(e.message);
      return false;
    } catch (e) {
      debugPrint('updatePassword error: $e');
      lastError = 'Нет связи с сервером';
      return false;
    }
  }

  Future<bool?> isEmailRegistered(String email) async {
    lastError = null;
    try {
      final res = await _db.rpc('email_registered', params: {'p_email': email});
      return res == true;
    } catch (e) {
      debugPrint('isEmailRegistered error: $e');
      lastError = 'Нет связи с сервером';
      return null;
    }
  }

  Future<bool> resetPasswordByEmail(String email, String newPassword) async {
    lastError = null;
    try {
      final res = await _db.rpc(
        'reset_password_by_email',
        params: {'p_email': email, 'p_new_password': newPassword},
      );
      if (res != true) {
        lastError = 'Пользователь с такой почтой не найден';
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('resetPasswordByEmail error: $e');
      lastError = 'Не удалось сменить пароль';
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _db.auth.signOut();
    } catch (e) {
      debugPrint('signOut error: $e');
    }
  }

  String _translate(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Неверная почта или пароль';
    }
    if (m.contains('email not confirmed')) {
      return 'Сначала подтвердите почту по ссылке из письма';
    }
    if (m.contains('already registered')) {
      return emailTakenMessage;
    }
    if (m.contains('should be different')) {
      return 'Новый пароль должен отличаться от старого';
    }
    if (m.contains('for security purposes')) {
      return 'Подождите минуту перед повторной отправкой';
    }
    if (m.contains('rate limit')) {
      return 'Слишком много попыток, попробуйте позже';
    }
    return message;
  }
}

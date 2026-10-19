import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/logo_header_scaffold.dart';
import '../../widgets/studdy_button.dart';
import '../../widgets/studdy_text_field.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _authService = AuthService();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String? _email;
  String? _passwordError;
  String? _confirmError;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final email = ModalRoute.of(context)?.settings.arguments;
    if (email is String) _email = email;
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = _password.text;

    setState(() {
      _passwordError = Validators.newPassword(password);
      _confirmError = Validators.confirmPassword(_confirm.text, password);
    });
    if (_passwordError != null || _confirmError != null) return;

    final email = _email;
    if (email == null) {
      _showMessage('Не указана почта. Начните восстановление заново');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final ok = await _authService.resetPasswordByEmail(email, password);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      _showMessage('Пароль изменён');
      Navigator.pop(context);
    } else {
      _showMessage(_authService.lastError ?? 'Не удалось сменить пароль');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LogoHeaderScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('< Назад', style: AppText.body),
                ),
              ),
            ),
            const SizedBox(height: 31),
            Text('Новый пароль',
                textAlign: TextAlign.center, style: AppText.title),
            const SizedBox(height: 15),
            Text(
              'Придумайте пароль для входа',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.navy50),
            ),
            const SizedBox(height: 14),
            StuddyTextField(
              controller: _password,
              hint: 'Новый пароль',
              height: 62,
              textInset: 47,
              errorText: _passwordError,
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
            ),
            const SizedBox(height: 18),
            StuddyTextField(
              controller: _confirm,
              hint: 'Повторите пароль',
              height: 62,
              textInset: 47,
              errorText: _confirmError,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_confirmError != null) setState(() => _confirmError = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17.5),
              child: StuddyButton(
                  label: 'Сохранить', loading: _loading, onPressed: _save),
            ),
            const SizedBox(height: 114),
          ],
        ),
      ),
    );
  }
}

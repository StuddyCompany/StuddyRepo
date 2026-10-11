import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/logo_header_scaffold.dart';
import '../../widgets/studdy_button.dart';
import '../../widgets/studdy_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _authService = AuthService();
  final _email = TextEditingController();

  String? _emailError;
  bool _loading = false;
  bool _argsRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final email = ModalRoute.of(context)?.settings.arguments;
    if (email is String) _email.text = email;
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final email = _email.text.trim();
    final error = Validators.email(email);
    if (error != null) {
      setState(() => _emailError = error);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final registered = await _authService.isEmailRegistered(email);
    if (!mounted) return;
    setState(() => _loading = false);

    if (registered == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authService.lastError ?? 'Нет связи с сервером'),
          backgroundColor: AppColors.navy,
        ),
      );
      return;
    }
    if (!registered) {
      setState(() => _emailError = 'Пользователь не найден');
      return;
    }

    Navigator.pushReplacementNamed(context, '/reset-password',
        arguments: email);
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
            Text('Забыли пароль?',
                textAlign: TextAlign.center, style: AppText.title),
            const SizedBox(height: 15),
            Text(
              'Пришлём ссылку для сброса на почту',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.navy50),
            ),
            const SizedBox(height: 14),
            StuddyTextField(
              controller: _email,
              hint: 'Почта',
              height: 62,
              textInset: 47,
              errorText: _emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              onSubmitted: (_) => _continue(),
            ),
            const SizedBox(height: 24),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17.5),
              child: StuddyButton(
                label: 'Отправить ссылку',
                loading: _loading,
                onPressed: _continue,
              ),
            ),
            const SizedBox(height: 114),
          ],
        ),
      ),
    );
  }
}

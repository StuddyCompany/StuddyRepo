import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/noise_background.dart';
import '../../widgets/studdy_button.dart';
import '../../widgets/studdy_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authService = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(() {
      _nameError = Validators.required(name);
      _emailError = Validators.email(email);
      _passwordError = Validators.newPassword(password);
      _confirmError = Validators.confirmPassword(_confirm.text, password);
    });
    if ([_nameError, _emailError, _passwordError, _confirmError]
        .any((e) => e != null)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final result = await _authService.signUp(email, password, name);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null) {
      final error = _authService.lastError ?? 'Не удалось зарегистрироваться';
      if (error == AuthService.emailTakenMessage) {
        setState(() => _emailError = error); // занятая почта — под полем
      } else {
        _showMessage(error);
      }
      return;
    }

    if (result) {
      // Сессия есть сразу → check.dart отправит на анкету.
      Navigator.pushNamedAndRemoveUntil(context, '/check', (route) => false);
      return;
    }

    // Включено подтверждение почты.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Подтвердите почту',
            style: AppText.body.copyWith(fontSize: 20)),
        content: Text(
          'Мы отправили письмо на $email. Перейдите по ссылке и войдите в аккаунт.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Понятно', style: AppText.body),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 393,
              child: NoiseBackground(),
            ),
            CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 191)),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(40)),
                    ),
                    child: _buildForm(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 39.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: const Offset(-2.5, 0),
              child: GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Text('< Назад', style: AppText.body),
              ),
            ),
          ),
          const SizedBox(height: 31),
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: const Offset(-2.5, 0),
              child: Text('Регистрация', style: AppText.title),
            ),
          ),
          const SizedBox(height: 15),
          StuddyTextField(
            controller: _name,
            hint: 'Имя',
            errorText: _nameError,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 18),
          StuddyTextField(
            controller: _email,
            hint: 'Почта',
            errorText: _emailError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
          ),
          const SizedBox(height: 18),
          StuddyTextField(
            controller: _password,
            hint: 'Пароль',
            errorText: _passwordError,
            obscureText: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
            },
          ),
          const SizedBox(height: 18),
          StuddyTextField(
            controller: _confirm,
            hint: 'Повторите пароль',
            errorText: _confirmError,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_confirmError != null) setState(() => _confirmError = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          const Spacer(flex: 68),
          StuddyButton(
            label: 'Зарегистрироваться',
            loading: _loading,
            onPressed: _submit,
          ),
          const Spacer(flex: 74),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

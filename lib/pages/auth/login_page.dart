import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/noise_background.dart';
import '../../widgets/studdy_button.dart';
import '../../widgets/studdy_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;

    setState(() {
      _emailError = Validators.email(email);
      _passwordError = Validators.required(password);
    });
    if (_emailError != null || _passwordError != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final ok = await _authService.signIn(email, password);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/check', (route) => false);
    } else {
      _showMessage(_authService.lastError ?? 'Не удалось войти');
    }
  }

  void _forgotPassword() {
    Navigator.pushNamed(context, '/forgot-password',
        arguments: _email.text.trim());
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
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 330,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 40,
                          top: 191,
                          child: Text('Привет!', style: AppText.hero),
                        ),
                        Positioned(
                          left: 44,
                          top: 259,
                          child: Text('Добро пожаловать в Studdy!',
                              style: AppText.heroSubtitle),
                        ),
                      ],
                    ),
                  ),
                ),
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
          const SizedBox(height: 27),
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: const Offset(-2.5, 0),
              child: Text('Вход', style: AppText.title),
            ),
          ),
          const SizedBox(height: 15),
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
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _forgotPassword,
              child: Text('Забыли пароль?', style: AppText.body),
            ),
          ),
          const SizedBox(height: 68),
          StuddyButton(label: 'Войти', loading: _loading, onPressed: _submit),
          const SizedBox(height: 24),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Нет аккаунта?',
                  style: AppText.body.copyWith(color: AppColors.blue50)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/register'),
                child: Text(
                  'Зарегистрироваться',
                  style: AppText.body.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 86),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class CheckPage extends StatefulWidget {
  const CheckPage({super.key});

  @override
  State<CheckPage> createState() => _CheckPageState();
}

class _CheckPageState extends State<CheckPage> {
  final _authService = AuthService();
  final _userService = UserService();
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // Минимум 0.8 с, чтобы заставка не мигала.
    final results = await Future.wait<Object?>([
      _nextRoute(),
      Future.delayed(const Duration(milliseconds: 800)),
    ]);
    final route = results.first as String?;
    if (!mounted) return;

    if (route == null) {
      setState(() => _failed = true);
      return;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  Future<String?> _nextRoute() async {
    if (!_authService.isLoggedIn) return '/login';
    final hasProfile = await _userService.hasProfile();
    if (hasProfile == null) return null; // ошибка сети/БД
    return hasProfile ? '/home' : '/profile-setup';
  }

  void _retry() {
    setState(() => _failed = false);
    _check();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Spacer(flex: 264),
              const AppIcon(AppIcons.logo, width: 183, height: 183),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text('Studdy', style: AppText.logo),
                  Positioned(
                    left: 4,
                    top: 102,
                    child: Text(
                      'your study buddy',
                      style: AppText.body.copyWith(color: AppColors.white),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 210),
              if (_failed)
                Column(
                  children: [
                    Text(
                      'Нет связи с сервером',
                      style: AppText.body.copyWith(color: AppColors.white),
                    ),
                    TextButton(
                      onPressed: _retry,
                      child: Text(
                        'Повторить',
                        style: AppText.body.copyWith(
                          color: AppColors.pink,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.pink,
                        ),
                      ),
                    ),
                  ],
                )
              else
                const AppIcon(AppIcons.logo, width: 70, height: 70),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

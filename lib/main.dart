import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/profile_setup_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/reset_password_page.dart';
import 'pages/check.dart';
import 'pages/home.dart';
import 'theme/app_theme.dart';
import 'pages/edit_profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  runApp(const StuddyApp());
}

class StuddyApp extends StatelessWidget {
  const StuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studdy',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: '/check',
      routes: {
        '/check': (context) => const CheckPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/profile-setup': (context) => const ProfileSetupPage(),
        '/home': (context) => const HomePage(),
        '/edit-profile': (context) => const EditProfilePage(),
      },
    );
  }
}

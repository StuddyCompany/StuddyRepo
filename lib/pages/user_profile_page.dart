import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'tabs/profile_tab.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: ProfileTab(userId: userId, showBack: true),
    );
  }
}
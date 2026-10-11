import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.title, this.child});

  final String title;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppText.section),
                const SizedBox(height: 8),
                Text(
                  'Раздел в разработке',
                  style: AppText.custom(16, AppColors.navy50),
                ),
                if (child != null) ...[
                  const SizedBox(height: 24),
                  child!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

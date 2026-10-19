import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';
import 'noise_background.dart';

class LogoHeaderScaffold extends StatelessWidget {
  const LogoHeaderScaffold({super.key, required this.child});

  final Widget child;

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
            const Positioned(
              top: 54,
              left: 0,
              right: 0,
              child: Center(child: AppIcon(AppIcons.logo, size: 110)),
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
                    child: child,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

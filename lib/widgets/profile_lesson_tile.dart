import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

class ProfileLessonTile extends StatelessWidget {
  const ProfileLessonTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onChat,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 28, right: 6),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.custom(12, AppColors.navy),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.custom(14, AppColors.pink),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onChat,
            child: const AppIcon(AppIcons.chatButton, size: 44),
          ),
        ],
      ),
    );
  }
}

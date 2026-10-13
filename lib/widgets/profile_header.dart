import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';
import 'user_avatar.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.title,
    this.onBack,
    this.avatarUrl,
    this.avatarBytes,
    this.onEditAvatar,
  });

  final String title;
  final VoidCallback? onBack;
  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final VoidCallback? onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 287,
      child: Stack(
        children: [
          Container(height: 222, color: AppColors.pink),
          Positioned(
            top: top + 33,
            left: 0,
            right: 0,
            child: Text(title, textAlign: TextAlign.center, style: AppText.screenHeader),
          ),
          if (onBack != null)
            Positioned(
              top: top + 36,
              left: 17,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: AppIcon(AppIcons.arrowBack, size: 16),
                ),
              ),
            ),
          Positioned(
            left: 32,
            top: 157,
            child: GestureDetector(
              onTap: onEditAvatar,
              child: Container(
                width: 130,
                height: 130,
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: UserAvatar(size: 120, url: avatarUrl, bytes: avatarBytes),
              ),
            ),
          ),
          if (onEditAvatar != null)
            Positioned(
              left: 125,
              top: 251,
              child: GestureDetector(
                onTap: onEditAvatar,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 14, color: AppColors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
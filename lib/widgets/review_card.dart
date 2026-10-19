import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_icon.dart';
import 'user_avatar.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context) {
    final sender = review['sender'] as Map<String, dynamic>?;
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = (review['comment'] as String?)?.trim() ?? '';

    return Container(
      constraints: const BoxConstraints(minHeight: 134),
      padding: const EdgeInsets.fromLTRB(12, 20, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 20, spreadRadius: -4),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(size: 54, url: sender?['avatar_url'] as String?),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Formatters.fullName(sender),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bold(18, AppColors.navy),
                      ),
                    ),
                    for (var i = 0; i < 5; i++)
                      Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: AppIcon(
                          AppIcons.star,
                          width: 13,
                          height: 12,
                          color: i < rating ? AppColors.pink : AppColors.pink50,
                        ),
                      ),
                  ],
                ),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    comment,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.custom(17, AppColors.navy).copyWith(height: 1.15),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
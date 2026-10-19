import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

class StuddyNavBar extends StatelessWidget {
  const StuddyNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (AppIcons.navHome, 24.0, 36.0),
    (AppIcons.navSearch, 24.0, 36.0),
    (AppIcons.logo, 30.0, 44.0),
    (AppIcons.navChat, 24.0, 36.0),
    (AppIcons.navProfile, 24.0, 36.0),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 78 + bottom,
      padding: EdgeInsets.only(left: 26, right: 26, bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 20)],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: SizedBox(
                  height: 64,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        _items[i].$1 == AppIcons.logo
                            ? -(i == currentIndex
                                    ? _items[i].$3
                                    : _items[i].$2) *
                                0.1
                            : 0,
                      ),
                      child: AppIcon(
                        _items[i].$1,
                        size: i == currentIndex ? _items[i].$3 : _items[i].$2,
                        color:
                            i == currentIndex ? AppColors.pink : AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

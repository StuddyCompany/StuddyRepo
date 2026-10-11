import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/studdy_nav_bar.dart';
import 'tabs/home_tab.dart';
import 'tabs/placeholder_tab.dart';
import 'tabs/profile_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(
            onOpenSearch: () => _select(1),
            onOpenLessons: () => _select(2),
            onOpenChats: () => _select(3),
          ),
          const PlaceholderTab(title: 'Поиск'),
          const PlaceholderTab(title: 'Занятия'),
          const PlaceholderTab(title: 'Чаты'),
          ProfileTab(
            onOpenLessons: () => _select(2),
            onOpenChats: () => _select(3),
          ),
        ],
      ),
      bottomNavigationBar: StuddyNavBar(currentIndex: _index, onTap: _select),
    );
  }
}

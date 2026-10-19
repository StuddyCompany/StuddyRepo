import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/studdy_nav_bar.dart';
import 'tabs/chats_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/lessons_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/search_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _lessonsKey = GlobalKey<LessonsTabState>();
  final _chatsKey = GlobalKey<ChatsTabState>();
  int _index = 0;

  void _select(int index) {
    setState(() => _index = index);
    if (index == 2) _lessonsKey.currentState?.reload();
    if (index == 3) _chatsKey.currentState?.reload();
  }

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
          const SearchTab(),
          LessonsTab(key: _lessonsKey, onOpenChats: () => _select(3)),
          ChatsTab(key: _chatsKey),
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

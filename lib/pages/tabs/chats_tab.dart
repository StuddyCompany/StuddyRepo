import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/user_avatar.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => ChatsTabState();
}

class ChatsTabState extends State<ChatsTab> {
  final _chat = ChatService();
  final _search = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _onlyUnread = false;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    reload();
    _channel = _chat.subscribe(onIncoming: (_) => reload());
  }

  @override
  void dispose() {
    final c = _channel;
    if (c != null) _chat.unsubscribe(c);
    _search.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    final items = await _chat.getConversations();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  int _unread(Map<String, dynamic> row) =>
      (row['unread_count'] as num?)?.toInt() ?? 0;

  int get _unreadChats => _items.where((r) => _unread(r) > 0).length;

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _items.where((r) {
      if (_onlyUnread && _unread(r) == 0) return false;
      if (q.isEmpty) return true;
      final haystack = '${Formatters.fullName(r)} '
              '${r['discipline'] ?? ''} '
              '${r['last_message'] ?? ''}'
          .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  Future<void> _open(String partnerId) async {
    await Navigator.pushNamed(context, '/chat', arguments: partnerId);
    reload();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: AppColors.pink,
      child: Column(
        children: [
          SizedBox(height: top + 33),
          Text('Чаты', style: AppText.screenHeader),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildSearchField(),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                _FilterPill(
                  label: 'Все',
                  count: _items.length,
                  selected: !_onlyUnread,
                  onTap: () => setState(() => _onlyUnread = false),
                ),
                const SizedBox(width: 10),
                _FilterPill(
                  label: 'Непрочитанные',
                  count: _unreadChats,
                  selected: _onlyUnread,
                  onTap: () => setState(() => _onlyUnread = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        style: AppText.custom(18, AppColors.navy),
        cursorColor: AppColors.navy,
        decoration: InputDecoration.collapsed(
          hintText: 'Поиск по чатам',
          hintStyle: AppText.custom(18, AppColors.navy50),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navy));
    }

    final items = _filtered;
    if (items.isEmpty) {
      final text = _items.isEmpty
          ? 'Пока нет переписок. Напишите репетитору из его профиля или из поиска'
          : 'Ничего не найдено';
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.custom(16, AppColors.navy50),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.navy,
      onRefresh: reload,
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 120),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildItem(items[i]),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> row) {
    final unread = _unread(row);
    final mine = row['last_sender_id'] == _chat.currentUserId;
    final message = '${mine ? 'Вы: ' : ''}${row['last_message'] ?? ''}'
        .replaceAll('\n', ' ');
    final sentAt = DateTime.parse(row['last_sent_at'] as String);
    final discipline = row['discipline'] as String?;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(row['partner_id'] as String),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: unread > 0 ? AppColors.selectedDay : AppColors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(size: 56, url: row['avatar_url'] as String?),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.fullName(row),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.custom(18, AppColors.navy),
                  ),
                  if (discipline != null && discipline.isNotEmpty)
                    Text(
                      discipline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.custom(12, AppColors.navy50),
                    ),
                  Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.custom(14, AppColors.navy),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.chatTime(sentAt),
                    style: AppText.custom(14, AppColors.navy),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: AppText.bold(12, AppColors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppText.bold(12, selected ? AppColors.white : AppColors.navy),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? const Color(0x4DFFFFFF) : AppColors.pink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count', style: AppText.bold(11, AppColors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

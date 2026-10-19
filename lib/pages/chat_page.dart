import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_icon.dart';
import '../widgets/user_avatar.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _chat = ChatService();
  final _userService = UserService();
  final _input = TextEditingController();

  String? _partnerId;
  Map<String, dynamic>? _partner;
  List<Map<String, dynamic>> _messages = [];
  RealtimeChannel? _channel;
  bool _loading = true;
  bool _sending = false;
  bool _argsRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) _partnerId = args;
    _load();
  }

  @override
  void dispose() {
    final c = _channel;
    if (c != null) _chat.unsubscribe(c);
    _input.dispose();
    super.dispose();
  }

  String get _subtitle {
    final links = (_partner?['user_disciplines'] as List?) ?? const [];
    final names = <String>[
      for (final link in links)
        if (link['discipline'] != null)
          (link['discipline'] as Map<String, dynamic>)['name'] as String,
    ]..sort();
    return names.isEmpty ? '' : names.first;
  }

  Future<void> _load() async {
    final id = _partnerId;
    if (id == null || id == _chat.currentUserId) {
      setState(() => _loading = false);
      return;
    }
    final results = await Future.wait<Object?>([
      _userService.getProfile(id),
      _chat.getMessages(id),
    ]);
    if (!mounted) return;
    setState(() {
      _partner = results[0] as Map<String, dynamic>?;
      _messages = results[1] as List<Map<String, dynamic>>;
      _loading = false;
    });
    _channel = _chat.subscribe(
      onIncoming: _onIncoming,
      onMyMessageUpdated: _onMyMessageUpdated,
    );
    _chat.markRead(id);
  }

  void _onIncoming(Map<String, dynamic> row) {
    final id = _partnerId;
    if (!mounted || id == null || row['sender_id'] != id) return;
    _add(row);
    _chat.markRead(id);
  }

  void _onMyMessageUpdated(Map<String, dynamic> row) {
    if (!mounted || row['recipient_id'] != _partnerId) return;
    setState(() {
      _messages = [
        for (final m in _messages)
          if (m['id'] == row['id']) {...m, ...row} else m,
      ];
    });
  }

  void _add(Map<String, dynamic> row) {
    if (_messages.any((m) => m['id'] == row['id'])) return;
    setState(() => _messages = [..._messages, row]);
  }

  Future<void> _send() async {
    final id = _partnerId;
    final text = _input.text.trim();
    if (id == null || text.isEmpty || _sending) return;

    _sending = true;
    _input.clear();
    final row = await _chat.sendMessage(id, text);
    _sending = false;
    if (!mounted) return;
    if (row == null) {
      _input.text = text; // вернём текст, чтобы он не потерялся
      _showMessage('Не удалось отправить сообщение');
      return;
    }
    _add(row);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.navy),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.pink,
        body: Column(
          children: [
            _buildHeader(top),
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    Expanded(child: _buildMessages()),
                    _buildInput(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double top) {
    final subtitle = _subtitle;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, top + 14, 18, 18),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: AppIcon(AppIcons.arrowBack, size: 16),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _partnerId == null
                  ? null
                  : () => Navigator.pushNamed(context, '/user-profile',
                      arguments: _partnerId),
              child: Row(
                children: [
                  UserAvatar(size: 58, url: _partner?['avatar_url'] as String?),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.fullName(_partner),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.screenHeader,
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.custom(15, AppColors.white),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navy));
    }
    if (_partnerId == null) {
      return Center(
        child: Text('Собеседник не найден',
            style: AppText.custom(16, AppColors.navy50)),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text('Напишите первое сообщение',
            style: AppText.custom(16, AppColors.navy50)),
      );
    }

    // reverse: true — новые сообщения внизу, список сам прижат к низу
    final list = _messages.reversed.toList();
    final me = _chat.currentUserId;

    return ListView.builder(
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final m = list[i];
        final date = DateTime.parse(m['sent_at'] as String).toLocal();
        final older = i + 1 < list.length
            ? DateTime.parse(list[i + 1]['sent_at'] as String).toLocal()
            : null;
        final showDate = older == null || !_sameDay(older, date);

        return Column(
          children: [
            if (showDate)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(Formatters.chatDay(date),
                    style: AppText.custom(12, AppColors.navy)),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Bubble(
                text: m['message_text'] as String,
                time: Formatters.time(date),
                mine: m['sender_id'] == me,
                read: m['read_at'] != null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showMessage('Вложения скоро будут доступны'),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(6, 10, 6, 10),
                  child: Icon(Icons.attach_file,
                      size: 24, color: AppColors.navy),
                ),
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppText.custom(16, AppColors.navy),
                    cursorColor: AppColors.navy,
                    decoration: InputDecoration.collapsed(
                      hintText: 'Сообщение...',
                      hintStyle: AppText.custom(16, AppColors.navy50),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: AppColors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.time,
    required this.mine,
    required this.read,
  });

  final String text;
  final String time;
  final bool mine;
  final bool read;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: mine ? AppColors.navy : AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                text,
                style:
                    AppText.custom(16, mine ? AppColors.white : AppColors.navy),
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: AppText.custom(11, AppColors.navy50)),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      read ? Icons.done_all : Icons.done,
                      size: 14,
                      color: read ? AppColors.blue : AppColors.navy50,
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

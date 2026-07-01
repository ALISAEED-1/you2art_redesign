import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/models/conversation.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/dm_repository.dart';
import 'conversation_page.dart';
import 'home_tab.dart';
import 'options_sheet.dart';
import 'widgets/empty_state.dart';

/// Messaging list — opens when the user selects the Chat tab in the bottom nav.
class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2F80ED);
  static const Color _badgeBg = Color(0xFFEAF2FF);
  static const Color _border = Color(0xFFECECEC);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _idleIcon = Color(0xFF9AA0A6);

  final ChatRepository _repo = ChatRepository();
  final DmRepository _dmRepo = DmRepository();

  List<DmThread> _threads = const [];
  List<Conversation> _samples = const [];
  bool _loading = true;

  final TextEditingController _searchCtrl = TextEditingController();
  String _q = '';
  RealtimeChannel? _inbox;

  @override
  void initState() {
    super.initState();
    _load();
    HomeTab.index.addListener(_onTab);
    ChatRefresh.tick.addListener(_onRefresh);
    _inbox = _dmRepo.subscribeInbox(_onRefresh);
  }

  void _onTab() {
    if (mounted && HomeTab.index.value == HomeTab.chat) _load();
  }

  void _onRefresh() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    HomeTab.index.removeListener(_onTab);
    ChatRefresh.tick.removeListener(_onRefresh);
    if (_inbox != null) _dmRepo.unsubscribe(_inbox!);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final t = await _dmRepo.fetchThreads();
      final s = await _repo.fetchConversations();
      if (!mounted) return;
      setState(() {
        _threads = t;
        _samples = s;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _reload() => _load();

  ImageProvider _img(String path) =>
      path.startsWith('http') ? NetworkImage(path) : AssetImage(path);

  String _threadTime(DmThread t) {
    final dt = t.lastAt;
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final threads = q.isEmpty
        ? _threads
        : _threads
            .where((t) => t.other.fullName.toLowerCase().contains(q))
            .toList();
    final samples = q.isEmpty
        ? _samples
        : _samples
            .where((c) => c.peerName.toLowerCase().contains(q))
            .toList();
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Chat',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    OptionsMenuButton(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border, width: 1.4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: _idleIcon, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _q = v),
                          cursorColor: _blue,
                          style: const TextStyle(
                              color: _textPrimary, fontSize: 15),
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Search Messages',
                            hintStyle:
                                TextStyle(color: _textSecondary, fontSize: 15),
                          ),
                        ),
                      ),
                      if (_q.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _q = '');
                          },
                          behavior: HitTestBehavior.opaque,
                          child: const Icon(Icons.close,
                              color: _idleIcon, size: 20),
                        ),
                    ],
                  ),
                ),
              ),
              Container(height: 4, color: const Color(0xFFEFEFEF)),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (threads.isEmpty && samples.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: EmptyState(
                      message: _q.isEmpty
                          ? 'No conversations yet.'
                          : 'No matches found.'),
                )
              else ...[
                // Real direct-message threads (with connections) first.
                for (final t in threads) ...[
                  GestureDetector(
                    onTap: () async {
                      final name = t.other.fullName.isNotEmpty
                          ? t.other.fullName
                          : 'You2Art User';
                      final photo = (t.other.avatarUrl ?? '').isNotEmpty
                          ? t.other.avatarUrl!
                          : 'assets/images/profile_pic.png';
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ConversationPage(
                            threadId: t.id,
                            name: name,
                            photo: photo,
                          ),
                        ),
                      );
                      _reload();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: _threadRow(t),
                    ),
                  ),
                  const Divider(
                      color: Color(0xFFEFEFEF), thickness: 1, height: 1),
                ],
                // Seeded sample conversations below.
                for (final c in samples) ...[
                  GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ConversationPage(
                            conversationId: c.id,
                            name: c.peerName,
                            photo: c.peerPhoto,
                          ),
                        ),
                      );
                      _reload();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: _chatRow(c),
                    ),
                  ),
                  const Divider(
                      color: Color(0xFFEFEFEF), thickness: 1, height: 1),
                ],
              ],
              const SizedBox(height: 96),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/edit_icon.png',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.edit, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _threadRow(DmThread t) {
    final name =
        t.other.fullName.isNotEmpty ? t.other.fullName : 'You2Art User';
    final photo = (t.other.avatarUrl ?? '').isNotEmpty
        ? t.other.avatarUrl!
        : 'assets/images/profile_pic.png';
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFEDEDED),
          backgroundImage: _img(photo),
          onBackgroundImageError: (_, __) {},
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                (t.lastBody ?? '').isNotEmpty
                    ? t.lastBody!
                    : 'Say hi 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                _threadTime(t),
                style: const TextStyle(color: _textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        if (t.unread > 0) ...[
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: _badgeBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              t.unread > 9 ? '9+' : '${t.unread}',
              style: const TextStyle(
                color: _blue,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _chatRow(Conversation c) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFEDEDED),
          backgroundImage: _img(c.peerPhoto),
          onBackgroundImageError: (_, __) {},
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.peerName,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                c.lastPreview ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                c.timeLabel ?? '',
                style: const TextStyle(color: _textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        if (c.unread > 0) ...[
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: _badgeBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${c.unread}',
              style: const TextStyle(
                color: _blue,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

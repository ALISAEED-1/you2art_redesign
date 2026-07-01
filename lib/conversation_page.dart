import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/models/conversation.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/dm_repository.dart';
import 'home_tab.dart';
import 'options_sheet.dart';

/// One-on-one conversation, opened from a row in the Chat list.
class ConversationPage extends StatefulWidget {
  const ConversationPage({
    super.key,
    this.conversationId,
    this.threadId,
    required this.name,
    required this.photo,
    this.lastOnline = '2 mins ago',
  });

  /// Sample conversation id (seeded chats) — used when [threadId] is null.
  final String? conversationId;

  /// Real direct-message thread id. When set, this is a live 1:1 chat.
  final String? threadId;
  final String name;
  final String photo;
  final String lastOnline;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  // ── Theme ────────────────────────────────────────────────────────────
  static const Color _outgoingBubble = Color(0xFF3A9BFF);
  static const Color _incomingBubble = Color(0xFFF1F2F5);
  static const Color _border = Color(0xFFECECEC);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ChatRepository _repo = ChatRepository();
  final DmRepository _dmRepo = DmRepository();

  bool get _isDirect => widget.threadId != null;

  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    if (_isDirect) {
      _channel = _dmRepo.subscribeThread(widget.threadId!, _onIncoming);
    }
  }

  void _onIncoming() {
    // A new message landed in this thread — refresh (also re-marks read).
    if (mounted) _load();
  }

  @override
  void dispose() {
    if (_channel != null) _dmRepo.unsubscribe(_channel!);
    // Let the Chat list refresh its threads / unread counts.
    ChatRefresh.bump();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final msgs = _isDirect
          ? await _dmRepo.fetchMessages(widget.threadId!)
          : await _repo.fetchMessages(widget.conversationId!);
      if (_isDirect) {
        // Clear unread for me; the chat list refreshes on return.
        unawaited(_dmRepo.markRead(widget.threadId!));
      }
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _messageController.clear();
    try {
      if (_isDirect) {
        await _dmRepo.sendMessage(widget.threadId!, text);
      } else {
        await _repo.sendMessage(widget.conversationId!, text);
      }
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  ImageProvider _img(String path) =>
      path.startsWith('http') ? NetworkImage(path) : AssetImage(path);

  // Groups consecutive messages from the same side together.
  List<List<ChatMessage>> _grouped() {
    final groups = <List<ChatMessage>>[];
    for (final m in _messages) {
      if (groups.isNotEmpty && groups.last.first.fromMe == m.fromMe) {
        groups.last.add(m);
      } else {
        groups.add([m]);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            const Divider(color: Color(0xFFEFEFEF), thickness: 1, height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? _emptyHint()
                      : ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          children: [
                            for (final g in _grouped()) ..._buildGroup(g),
                          ],
                        ),
            ),
            const Divider(color: Color(0xFFEFEFEF), thickness: 1, height: 1),
            const SizedBox(height: 10),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  // Shown for a brand-new thread with no messages yet.
  Widget _emptyHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 48, color: _textSecondary),
            const SizedBox(height: 14),
            Text(
              "You're connected with ${widget.name}.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Say hello 👋 and start the conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEDEDED),
            backgroundImage: _img(widget.photo),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last online, ${widget.lastOnline}',
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const OptionsMenuButton(),
        ],
      ),
    );
  }

  List<Widget> _buildGroup(List<ChatMessage> g) {
    final isMe = g.first.fromMe;
    return [
      for (final m in g) ...[
        _bubble(m.body, isMe: isMe),
        const SizedBox(height: 8),
      ],
      Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 16),
          child: Text(
            g.last.timeLabel ?? '',
            style: const TextStyle(color: _textSecondary, fontSize: 11),
          ),
        ),
      ),
    ];
  }

  Widget _bubble(String text, {required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.7,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? _outgoingBubble : _incomingBubble,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isMe ? Colors.white : _textPrimary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _border, width: 1.4),
              ),
              child: TextField(
                controller: _messageController,
                cursorColor: Colors.black,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Enter your message',
                  hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

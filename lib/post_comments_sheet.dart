import 'package:flutter/material.dart';

import 'data/repositories/post_repository.dart';
import 'widgets/empty_state.dart';

/// Bottom-sheet listing the comments on a post, with an input to add one.
Future<void> showPostCommentsSheet(
  BuildContext context, {
  String? postId,
  required String count,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PostCommentsSheet(postId: postId, count: count),
  );
}

class _PostCommentsSheet extends StatefulWidget {
  const _PostCommentsSheet({required this.postId, required this.count});

  final String? postId;
  final String count;

  @override
  State<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<_PostCommentsSheet> {
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _bubble = Color(0xFFF4F5F7);
  static const Color _border = Color(0xFFECECEC);

  final PostRepository _repo = PostRepository();
  final _controller = TextEditingController();

  List<Map<String, String>> _comments = const [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.postId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final comments = await _repo.fetchComments(widget.postId!);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || widget.postId == null) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await _repo.addComment(widget.postId!, text);
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  ImageProvider _img(String path) =>
      path.startsWith('http') ? NetworkImage(path) : AssetImage(path);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Post Comments (${widget.count})',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFE0E0E0), width: 1.2),
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: _textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const Divider(color: Color(0xFFF0F0F0), height: 1, thickness: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const EmptyState(
                          message: 'No comments yet.\nBe the first to comment!',
                          imageSize: 120,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          itemCount: _comments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (_, i) => _commentTile(_comments[i]),
                        ),
            ),
            if (widget.postId != null) _composer(),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _border, width: 1.4),
                ),
                child: TextField(
                  controller: _controller,
                  cursorColor: Colors.black,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(color: _textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Write a comment…',
                    hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 46,
                height: 46,
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
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commentTile(Map<String, String> c) {
    final avatar = c['avatar'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFEDEDED),
              backgroundImage: avatar.isEmpty
                  ? const AssetImage('assets/images/profile_pic.png')
                  : _img(avatar),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                c['name'] ?? '',
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _bubble,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            c['body'] ?? '',
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

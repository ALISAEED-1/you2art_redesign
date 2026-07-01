import 'package:flutter/material.dart';

import 'data/repositories/post_repository.dart';
import 'widgets/empty_state.dart';

/// Bottom-sheet listing the people who liked a post.
Future<void> showPostLikesSheet(
  BuildContext context, {
  String? postId,
  required String count,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PostLikesSheet(postId: postId, count: count),
  );
}

class _PostLikesSheet extends StatefulWidget {
  const _PostLikesSheet({required this.postId, required this.count});

  final String? postId;
  final String count;

  @override
  State<_PostLikesSheet> createState() => _PostLikesSheetState();
}

class _PostLikesSheetState extends State<_PostLikesSheet> {
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);

  final PostRepository _repo = PostRepository();
  late Future<List<Map<String, String>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.postId == null
        ? Future.value(const [])
        : _repo.fetchLikers(widget.postId!);
  }

  ImageProvider _img(String path) =>
      path.startsWith('http') ? NetworkImage(path) : AssetImage(path);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
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
                        'Post Likes (${widget.count})',
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
                            color: const Color(0xFFE0E0E0),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: _textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, String>>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final likers = snapshot.data ?? const [];
                    if (likers.isEmpty) {
                      return const EmptyState(
                          message: 'No likes yet.', imageSize: 120);
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      itemCount: likers.length,
                      separatorBuilder: (_, __) => SizedBox(
                        height: 1,
                        child: OverflowBox(
                          maxWidth: MediaQuery.sizeOf(context).width,
                          child: Container(
                            height: 1,
                            color: const Color(0xFFF0F0F0),
                          ),
                        ),
                      ),
                      itemBuilder: (_, i) => _likerRow(likers[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _likerRow(Map<String, String> liker) {
    final avatar = liker['avatar'] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEDEDED),
            backgroundImage: avatar.isEmpty
                ? const AssetImage('assets/images/profile_pic.png')
                : _img(avatar),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              liker['name'] ?? '',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

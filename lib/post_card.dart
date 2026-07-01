import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'options_sheet.dart';
import 'post_comments_sheet.dart';
import 'post_likes_sheet.dart';
import 'providers/post_provider.dart';
import 'share_post_sheet.dart';

/// Reusable post card used by the home feed and the search results.
///
/// [post] is a loosely-typed map with the keys: name, time, body, tags,
/// image, likes, comments, shares — any of which can be absent. The card
/// renders only what's present.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final Map<String, dynamic> post;

  static const Color _blue = Color(0xFF2F80ED);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF8A8F98);
  static const Color _idleIcon = Color(0xFF9AA0A6);

  @override
  Widget build(BuildContext context) {
    // Caller is expected to provide horizontal padding. Full-bleed elements
    // (image) use OverflowBox to escape that padding regardless.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
          if (post['body'] != null) ...[
            const SizedBox(height: 12),
            Text(
              post['body'] as String,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
          if (post['tags'] != null) ...[
            const SizedBox(height: 8),
            Text(
              post['tags'] as String,
              style: const TextStyle(
                color: _blue,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if ((post['tagged'] as List?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            _taggedLine(post['tagged'] as List),
          ],
          if (post['image'] != null) ...[
            const SizedBox(height: 12),
            _fullWidthImage(context, post['image'] as String),
          ],
        const SizedBox(height: 14),
        _engagementRow(context),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFEDEDED),
          backgroundImage: _imageProvider(
            post['photo'] as String?,
            'assets/images/profile_pic.png',
          ),
          onBackgroundImageError: (_, __) {},
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['name'] as String,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                post['time'] as String,
                style: const TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const OptionsMenuButton(
          containerPadding: EdgeInsets.all(6),
          iconSize: 18,
          borderColor: Color(0xFFECECEC),
        ),
      ],
    );
  }

  Widget _fullWidthImage(BuildContext context, String src) {
    final width = MediaQuery.sizeOf(context).width;
    // Portrait container — width fills the screen, height scales with width.
    final height = width * 1.05;
    final placeholder = Container(
      width: width,
      height: height,
      color: const Color(0xFFEDEDED),
      child: const Icon(Icons.image, size: 48, color: _idleIcon),
    );
    final isNetwork = src.startsWith('http');
    return SizedBox(
      height: height,
      child: OverflowBox(
        maxWidth: width,
        child: isNetwork
            ? Image.network(
                src,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder,
              )
            : Image.asset(
                src,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder,
              ),
      ),
    );
  }

  /// Network image when [path] is a URL, otherwise a bundled asset.
  ImageProvider _imageProvider(String? path, String fallbackAsset) {
    if (path != null && path.startsWith('http')) return NetworkImage(path);
    return AssetImage(path ?? fallbackAsset);
  }

  Widget _engagementRow(BuildContext context) {
    final id = post['id'] as String?;
    final liked = post['liked'] == true;
    final likes = post['likes'] as String? ?? '0';
    final comments = post['comments'] as String? ?? '0';
    return Row(
      children: [
        _likeItem(context, id, liked, likes),
        const SizedBox(width: 24),
        _engagementItem(
          'assets/images/comment_icon.png',
          Icons.chat_bubble_outline,
          comments,
          onTap: () async {
            await showPostCommentsSheet(context, postId: id, count: comments);
            if (context.mounted && id != null) {
              context.read<PostProvider>().loadFeed();
            }
          },
        ),
        const SizedBox(width: 24),
        _engagementItem(
          'assets/images/share_icon.png',
          Icons.share_outlined,
          post['shares'] as String? ?? '0',
          onTap: () async {
            final pid = post['id'] as String?;
            final name = (post['name'] as String?) ?? 'You2Art';
            final body = (post['body'] as String?) ?? '';
            final link = pid != null
                ? 'https://you2art.app/post/$pid'
                : 'https://you2art.app';
            final text = body.isNotEmpty
                ? '$name on You2Art:\n$body\n\n$link'
                : '$name shared a post on You2Art\n$link';
            await showSharePostSheet(context,
                postId: pid, shareText: text, shareLink: link);
            if (context.mounted && pid != null) {
              context.read<PostProvider>().loadFeed();
            }
          },
        ),
      ],
    );
  }

  Widget _taggedLine(List tagged) {
    final names = tagged.map((e) => e.toString()).toList();
    final label = names.length <= 2
        ? names.join(' and ')
        : '${names.take(2).join(', ')} +${names.length - 2} more';
    return Row(
      children: [
        const Icon(Icons.local_offer_outlined, size: 14, color: _blue),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'with $label',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: _blue, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // Tap the heart to like/unlike; tap the count to see who liked.
  Widget _likeItem(BuildContext context, String? id, bool liked, String count) {
    return Row(
      children: [
        GestureDetector(
          onTap:
              id == null ? null : () => context.read<PostProvider>().toggleLike(id),
          behavior: HitTestBehavior.opaque,
          child: liked
              ? const Icon(Icons.favorite, color: Color(0xFFE53935), size: 18)
              : Image.asset(
                  'assets/images/heart_icon.png',
                  width: 18,
                  height: 18,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: _textSecondary),
                ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => showPostLikesSheet(context, postId: id, count: count),
          behavior: HitTestBehavior.opaque,
          child: Text(
            count,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _engagementItem(
    String asset,
    IconData fallbackIcon,
    String count, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Image.asset(
            asset,
            width: 18,
            height: 18,
            errorBuilder: (_, __, ___) =>
                Icon(fallbackIcon, size: 18, color: _textSecondary),
          ),
          const SizedBox(width: 6),
          Text(
            count,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

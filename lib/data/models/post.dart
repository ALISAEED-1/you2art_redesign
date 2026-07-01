/// A feed post, mirroring `public.posts` joined with its author + counts.
class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
    this.body,
    this.tags,
    this.imageUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.likedByMe = false,
    this.taggedNames = const [],
  });

  final String id;
  final String authorId;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? body;
  final String? tags;
  final String? imageUrl;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool likedByMe;
  final List<String> taggedNames;

  Post copyWith({int? likeCount, bool? likedByMe}) => Post(
        id: id,
        authorId: authorId,
        createdAt: createdAt,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        body: body,
        tags: tags,
        imageUrl: imageUrl,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount,
        shareCount: shareCount,
        likedByMe: likedByMe ?? this.likedByMe,
        taggedNames: taggedNames,
      );

  factory Post.fromMap(Map<String, dynamic> map) {
    final author = map['author'] as Map<String, dynamic>?;
    final first = author?['first_name'] as String?;
    final last = author?['last_name'] as String?;
    final name = [first, last]
        .where((e) => (e ?? '').trim().isNotEmpty)
        .join(' ')
        .trim();
    return Post(
      id: map['id'] as String,
      authorId: (map['author_id'] ?? author?['id'] ?? '') as String,
      authorName: name.isNotEmpty ? name : null,
      authorAvatarUrl: author?['avatar_url'] as String?,
      body: map['body'] as String?,
      tags: map['tags'] as String?,
      imageUrl: map['image_url'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      likeCount: _embeddedCount(map['likes']),
      commentCount: _embeddedCount(map['comments']),
      shareCount: _embeddedCount(map['shares']),
      likedByMe: map['liked'] == true,
      taggedNames: _parseTagged(map['tagged']),
    );
  }

  static List<String> _parseTagged(dynamic embed) {
    if (embed is! List) return const [];
    final out = <String>[];
    for (final e in embed) {
      if (e is Map && e['profile'] is Map) {
        final p = e['profile'] as Map;
        final n = [p['first_name'], p['last_name']]
            .where((x) => (x ?? '').toString().trim().isNotEmpty)
            .join(' ')
            .trim();
        if (n.isNotEmpty) out.add(n);
      }
    }
    return out;
  }

  /// Adapts this post to the loosely-typed map that [PostCard] consumes.
  Map<String, dynamic> toCardMap() => {
        'id': id,
        'liked': likedByMe,
        'name': authorName ?? 'You2Art User',
        if ((authorAvatarUrl ?? '').isNotEmpty) 'photo': authorAvatarUrl,
        'time': _relativeTime(createdAt),
        if ((body ?? '').isNotEmpty) 'body': body,
        if ((tags ?? '').isNotEmpty) 'tags': tags,
        if ((imageUrl ?? '').isNotEmpty) 'image': imageUrl,
        'likes': _formatCount(likeCount),
        'comments': _formatCount(commentCount),
        'shares': _formatCount(shareCount),
        if (taggedNames.isNotEmpty) 'tagged': taggedNames,
      };

  static int _embeddedCount(dynamic embed) {
    if (embed is List && embed.isNotEmpty) {
      final c = embed.first['count'];
      if (c is int) return c;
    }
    return 0;
  }
}

String _relativeTime(DateTime dt) {
  final d = DateTime.now().difference(dt);
  if (d.inSeconds < 60) return 'Just Now';
  if (d.inMinutes < 60) return '${d.inMinutes}m Ago';
  if (d.inHours < 24) return '${d.inHours}h Ago';
  if (d.inDays < 7) return '${d.inDays}d Ago';
  if (d.inDays < 30) return '${(d.inDays / 7).floor()}w Ago';
  if (d.inDays < 365) return '${(d.inDays / 30).floor()}mo Ago';
  return '${(d.inDays / 365).floor()}y Ago';
}

String _formatCount(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final k = n / 1000;
    return '${k.toStringAsFixed(n % 1000 >= 100 ? 1 : 0)}K';
  }
  return '${(n / 1000000).toStringAsFixed(1)}M';
}

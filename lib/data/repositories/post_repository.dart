import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../models/post.dart';

/// Reads the feed and creates posts (with optional image upload).
class PostRepository {
  SupabaseClient get _client => SupabaseConfig.client;
  String? get _uid => _client.auth.currentUser?.id;

  static const String _selectWithAuthorAndCounts =
      'id, author_id, body, tags, image_url, created_at, '
      'author:profiles!author_id(id, first_name, last_name, category, avatar_url), '
      'likes:post_likes(count), comments:post_comments(count), '
      'shares:post_shares(count), '
      'tagged:post_tags(profile:profiles!tagged_user_id(first_name, last_name))';

  /// All posts, newest first, with author info, counts, and whether the
  /// current user has liked each one.
  Future<List<Post>> fetchFeed() async {
    final rows = await _client
        .from('posts')
        .select(_selectWithAuthorAndCounts)
        .order('created_at', ascending: false);
    final likedIds = await _myLikedPostIds();
    return (rows as List).map((e) {
      final m = e as Map<String, dynamic>;
      return Post.fromMap({...m, 'liked': likedIds.contains(m['id'])});
    }).toList();
  }

  Future<Set<String>> _myLikedPostIds() async {
    final uid = _uid;
    if (uid == null) return <String>{};
    final rows =
        await _client.from('post_likes').select('post_id').eq('user_id', uid);
    return (rows as List).map((e) => e['post_id'] as String).toSet();
  }

  /// Likes or unlikes a post for the current user.
  Future<void> toggleLike(String postId, bool like) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    if (like) {
      await _client
          .from('post_likes')
          .upsert({'post_id': postId, 'user_id': uid});
    } else {
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid);
    }
  }

  /// People who liked [postId] — {name, avatar}.
  Future<List<Map<String, String>>> fetchLikers(String postId) async {
    final rows = await _client
        .from('post_likes')
        .select('liker:profiles!user_id(first_name, last_name, avatar_url)')
        .eq('post_id', postId);
    return (rows as List).map((e) {
      final p = e['liker'] as Map<String, dynamic>?;
      return {'name': _name(p), 'avatar': (p?['avatar_url'] as String?) ?? ''};
    }).toList();
  }

  /// Comments on [postId], oldest first — {name, avatar, body}.
  Future<List<Map<String, String>>> fetchComments(String postId) async {
    final rows = await _client
        .from('post_comments')
        .select(
            'body, created_at, author:profiles!author_id(first_name, last_name, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return (rows as List).map((e) {
      final p = e['author'] as Map<String, dynamic>?;
      return {
        'name': _name(p),
        'avatar': (p?['avatar_url'] as String?) ?? '',
        'body': (e['body'] as String?) ?? '',
      };
    }).toList();
  }

  Future<void> addComment(String postId, String body) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    await _client
        .from('post_comments')
        .insert({'post_id': postId, 'author_id': uid, 'body': body});
  }

  String _name(Map<String, dynamic>? p) {
    final name = [p?['first_name'], p?['last_name']]
        .where((e) => (e ?? '').toString().trim().isNotEmpty)
        .join(' ')
        .trim();
    return name.isEmpty ? 'You2Art User' : name;
  }

  /// The current user's own posts, newest first.
  Future<List<Post>> fetchMyPosts() async {
    final uid = _uid;
    if (uid == null) return const [];
    return fetchPostsByUser(uid);
  }

  /// Posts authored by [userId], newest first.
  Future<List<Post>> fetchPostsByUser(String userId) async {
    final rows = await _client
        .from('posts')
        .select(_selectWithAuthorAndCounts)
        .eq('author_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Post.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a post, uploading [image] to the post-images bucket first if
  /// given, and tagging [taggedUserIds] (which notifies them).
  Future<void> createPost({
    String? body,
    String? tags,
    File? image,
    List<String> taggedUserIds = const [],
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');

    String? imageUrl;
    if (image != null) imageUrl = await _uploadImage(uid, image);

    final inserted = await _client
        .from('posts')
        .insert({
          'author_id': uid,
          'body': body,
          'tags': tags,
          'image_url': imageUrl,
        })
        .select('id')
        .single();
    final postId = inserted['id'] as String;

    if (taggedUserIds.isNotEmpty) {
      await _client.from('post_tags').insert([
        for (final id in taggedUserIds)
          {'post_id': postId, 'tagged_user_id': id},
      ]);
    }
  }

  /// Records that the current user shared [postId] (notifies the post owner).
  Future<void> recordShare(String postId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('post_shares')
        .insert({'post_id': postId, 'user_id': uid});
  }

  Future<String> _uploadImage(String uid, File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from('post-images').upload(path, file);
    return _client.storage.from('post-images').getPublicUrl(path);
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/models/post.dart';
import '../data/repositories/post_repository.dart';

/// App-wide feed state: the list of posts plus loading/creating status.
class PostProvider extends ChangeNotifier {
  PostProvider({PostRepository? repository})
      : _repo = repository ?? PostRepository();

  final PostRepository _repo;

  List<Post> _feed = const [];
  List<Post> get feed => _feed;

  bool _loading = false;
  bool get loading => _loading;

  bool _posting = false;
  bool get posting => _posting;

  String? _error;
  String? get error => _error;

  /// Loads the whole feed (newest first).
  Future<void> loadFeed() async {
    _loading = true;
    notifyListeners();
    try {
      _feed = await _repo.fetchFeed();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  /// Likes/unlikes a post with an optimistic UI update.
  Future<void> toggleLike(String postId) async {
    final idx = _feed.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final original = _feed[idx];
    final nowLiked = !original.likedByMe;
    _feed[idx] = original.copyWith(
      likedByMe: nowLiked,
      likeCount: (original.likeCount + (nowLiked ? 1 : -1)).clamp(0, 1 << 31),
    );
    notifyListeners();
    try {
      await _repo.toggleLike(postId, nowLiked);
    } catch (_) {
      _feed[idx] = original; // revert on failure
      notifyListeners();
    }
  }

  /// Creates a post then refreshes the feed. Returns true on success.
  Future<bool> createPost({
    String? body,
    String? tags,
    File? image,
    List<String> taggedUserIds = const [],
  }) async {
    _posting = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.createPost(
          body: body, tags: tags, image: image, taggedUserIds: taggedUserIds);
      await _repo.fetchFeed().then((value) => _feed = value);
      _posting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _posting = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

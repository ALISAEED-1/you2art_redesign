import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../models/profile_media.dart';

/// Reads/writes the current user's profile photos & videos (`profile_media`).
class MediaRepository {
  SupabaseClient get _client => SupabaseConfig.client;
  String? get _uid => _client.auth.currentUser?.id;

  Future<List<ProfileMedia>> fetchMyMedia() async {
    final uid = _uid;
    if (uid == null) return const [];
    return fetchMediaFor(uid);
  }

  Future<List<ProfileMedia>> fetchMediaFor(String userId) async {
    final rows = await _client
        .from('profile_media')
        .select()
        .eq('profile_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => ProfileMedia.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addVideo({required String title, required String link}) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    await _client.from('profile_media').insert({
      'profile_id': uid,
      'type': 'video',
      'title': title,
      'link': link,
    });
  }

  /// Uploads [file] to the post-images bucket and saves a photo media row.
  Future<void> addPhoto({
    required File file,
    String? title,
    String? link,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    final raw = file.path.split('.').last.toLowerCase();
    final ext =
        const ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(raw) ? raw : 'jpg';
    final path = '$uid/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bytes = await file.readAsBytes();
    await _client.storage.from('post-images').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
          ),
        );
    final url = _client.storage.from('post-images').getPublicUrl(path);
    await _client.from('profile_media').insert({
      'profile_id': uid,
      'type': 'photo',
      'url': url,
      'title': title,
      'link': link,
    });
  }

  /// Saves a photo media row from a pasted external link (no upload).
  Future<void> addPhotoLink({required String url, String? title}) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    await _client.from('profile_media').insert({
      'profile_id': uid,
      'type': 'photo',
      'url': url,
      'title': title,
    });
  }

  Future<void> deleteMedia(String id) async {
    await _client.from('profile_media').delete().eq('id', id);
  }
}

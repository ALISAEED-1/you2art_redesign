import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../models/profile.dart';

/// Reads/writes the signed-in user's row in `public.profiles` and uploads the
/// profile photo to the `avatars` storage bucket.
class ProfileRepository {
  SupabaseClient get _client => SupabaseConfig.client;
  String? get _uid => _client.auth.currentUser?.id;

  /// The current user's profile, or null if not signed in / no row yet.
  Future<Profile?> fetchMyProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final data =
        await _client.from('profiles').select().eq('id', uid).maybeSingle();
    return data == null ? null : Profile.fromMap(data);
  }

  /// Applies [changes] to the current user's profile row and returns the
  /// updated profile. The row already exists (created by the signup trigger).
  Future<Profile> updateMyProfile(Map<String, dynamic> changes) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    final data = await _client
        .from('profiles')
        .update(changes)
        .eq('id', uid)
        .select()
        .single();
    return Profile.fromMap(data);
  }

  /// Searches profiles by name (first or last, case-insensitive), excluding
  /// the current user. Returns up to 20 matches.
  Future<List<Profile>> searchProfiles(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final uid = _uid;
    var req = _client
        .from('profiles')
        .select()
        .or('first_name.ilike.%$q%,last_name.ilike.%$q%');
    if (uid != null) req = req.neq('id', uid);
    final rows = await req.limit(20);
    return (rows as List)
        .map((e) => Profile.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// People the current user can tag/pick (all profiles except self),
  /// optionally filtered by name. Ordered by name.
  Future<List<Profile>> fetchPeople({String query = ''}) async {
    final uid = _uid;
    final q = query.trim();
    var req = _client.from('profiles').select();
    if (q.isNotEmpty) {
      req = req.or('first_name.ilike.%$q%,last_name.ilike.%$q%');
    }
    if (uid != null) req = req.neq('id', uid);
    final rows = await req.order('first_name', ascending: true).limit(50);
    return (rows as List)
        .map((e) => Profile.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Uploads [file] to the `avatars` bucket and returns its public URL.
  Future<String> uploadAvatar(File file) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    final raw = file.path.split('.').last.toLowerCase();
    final ext =
        const ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(raw) ? raw : 'jpg';
    // Unique filename so the public URL changes on every upload (avoids the
    // CDN/image cache serving a stale photo).
    final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bytes = await file.readAsBytes();
    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
          ),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }
}

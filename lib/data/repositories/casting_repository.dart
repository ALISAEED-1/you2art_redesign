import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../models/casting_application.dart';
import '../models/casting_call.dart';

/// Reads/writes casting calls and applications.
class CastingRepository {
  SupabaseClient get _client => SupabaseConfig.client;
  String? get _uid => _client.auth.currentUser?.id;

  /// All casting calls (browse). Flags whether the current user applied to
  /// each one, and whether they own it.
  Future<List<CastingCall>> fetchAllCalls() async {
    final rows = await _client
        .from('casting_calls')
        .select('*, profiles!owner_id(avatar_url, first_name, last_name)')
        .order('created_at', ascending: false);
    final appliedIds = await _myAppliedCallIds();
    final uid = _uid;
    return (rows as List).map((e) {
      final m = e as Map<String, dynamic>;
      return CastingCall.fromMap({
        ...m,
        'applied': appliedIds.contains(m['id']),
        'is_mine': uid != null && m['owner_id'] == uid,
      });
    }).toList();
  }

  /// IDs of casting calls the current user has applied to.
  Future<Set<String>> _myAppliedCallIds() async {
    final uid = _uid;
    if (uid == null) return <String>{};
    final rows = await _client
        .from('casting_applications')
        .select('casting_call_id')
        .eq('applicant_id', uid);
    return (rows as List).map((e) => e['casting_call_id'] as String).toSet();
  }

  /// Calls created by the current user, with applicant counts.
  Future<List<CastingCall>> fetchMyCalls() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client
        .from('casting_calls')
        .select(
            '*, casting_applications(count), profiles!owner_id(avatar_url, first_name, last_name)')
        .eq('owner_id', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => CastingCall.fromMap(
            {...(e as Map<String, dynamic>), 'is_mine': true}))
        .toList();
  }

  /// Calls the current user has applied to.
  Future<List<CastingCall>> fetchAppliedCalls() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client
        .from('casting_applications')
        .select(
            'casting_call:casting_calls(*, profiles!owner_id(avatar_url, first_name, last_name))')
        .eq('applicant_id', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .where((e) => e['casting_call'] != null)
        .map((e) => CastingCall.fromMap({
              ...e['casting_call'] as Map<String, dynamic>,
              'applied': true,
            }))
        .toList();
  }

  Future<void> createCall(Map<String, dynamic> data) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    await _client.from('casting_calls').insert({...data, 'owner_id': uid});
  }

  Future<void> deleteCall(String id) async {
    await _client.from('casting_calls').delete().eq('id', id);
  }

  Future<void> apply({
    required String callId,
    required String name,
    required String photo,
    String? phone,
    String? email,
    String? note,
    String? age,
    String? height,
    String? gender,
    String? experience,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    await _client.from('casting_applications').insert({
      'casting_call_id': callId,
      'applicant_id': uid,
      'applicant_name': name,
      'applicant_photo': photo,
      'phone': phone,
      'email': email,
      'note': note,
      'age': age,
      'height': height,
      'gender': gender,
      'experience': experience,
      'status': 'received',
    });
  }

  /// Applications to [callId], optionally filtered by [status].
  Future<List<CastingApplication>> fetchApplications(
    String callId, {
    String? status,
  }) async {
    var query =
        _client.from('casting_applications').select().eq('casting_call_id', callId);
    if (status != null) query = query.eq('status', status);
    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((e) => CastingApplication.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setApplicationStatus(String applicationId, String status) async {
    await _client
        .from('casting_applications')
        .update({'status': status}).eq('id', applicationId);
  }
}

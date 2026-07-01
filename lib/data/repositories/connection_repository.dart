import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../models/profile.dart';

/// My connection state with another user.
enum ConnState { none, outgoingPending, incomingPending, connected }

/// A connection edge paired with the OTHER user's profile (for lists).
class ConnectionEdge {
  const ConnectionEdge({
    required this.id,
    required this.status,
    required this.other,
  });

  final String id;
  final String status; // 'pending' | 'accepted'
  final Profile other;
}

/// Reads/writes the social graph in `public.connections`.
class ConnectionRepository {
  SupabaseClient get _client => SupabaseConfig.client;
  String? get _uid => _client.auth.currentUser?.id;

  String _pair(String a, String b) =>
      'and(requester_id.eq.$a,addressee_id.eq.$b)';

  /// The current user's connection state with [otherId].
  Future<ConnState> stateWith(String otherId) async {
    final uid = _uid;
    if (uid == null) return ConnState.none;
    final rows = await _client
        .from('connections')
        .select('requester_id, addressee_id, status')
        .or('${_pair(uid, otherId)},${_pair(otherId, uid)}')
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return ConnState.none;
    final r = list.first as Map<String, dynamic>;
    if (r['status'] == 'accepted') return ConnState.connected;
    return r['requester_id'] == uid
        ? ConnState.outgoingPending
        : ConnState.incomingPending;
  }

  /// Send a connection request to [addresseeId].
  Future<void> sendRequest(String addresseeId) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    await _client.from('connections').insert({
      'requester_id': uid,
      'addressee_id': addresseeId,
      'status': 'pending',
    });
  }

  /// Accept the pending request sent to me by [requesterId].
  Future<void> acceptFrom(String requesterId) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    await _client
        .from('connections')
        .update({
          'status': 'accepted',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('requester_id', requesterId)
        .eq('addressee_id', uid);
  }

  /// Delete the edge between me and [otherId] (reject / cancel / disconnect).
  Future<void> removeWith(String otherId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('connections')
        .delete()
        .or('${_pair(uid, otherId)},${_pair(otherId, uid)}');
  }

  /// Pending requests sent TO me, with the requester's profile.
  Future<List<ConnectionEdge>> incomingRequests() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client
        .from('connections')
        .select('id, status, requester:profiles!requester_id(*)')
        .eq('addressee_id', uid)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) {
          final m = e as Map<String, dynamic>;
          final other = m['requester'];
          if (other is! Map) return null;
          return ConnectionEdge(
            id: m['id'] as String,
            status: m['status'] as String,
            other: Profile.fromMap(other.cast<String, dynamic>()),
          );
        })
        .whereType<ConnectionEdge>()
        .toList();
  }

  /// People to suggest connecting with: profiles I'm not already linked to
  /// (no pending/accepted edge) and not myself.
  Future<List<Profile>> suggestions({int limit = 12}) async {
    final uid = _uid;
    if (uid == null) return const [];
    final edges = await _client
        .from('connections')
        .select('requester_id, addressee_id')
        .or('requester_id.eq.$uid,addressee_id.eq.$uid');
    final exclude = <String>{uid};
    for (final e in (edges as List)) {
      final m = e as Map<String, dynamic>;
      exclude.add(m['requester_id'] as String);
      exclude.add(m['addressee_id'] as String);
    }
    final rows = await _client
        .from('profiles')
        .select()
        .not('id', 'in', '(${exclude.join(',')})')
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((e) => Profile.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// All accepted connections (either direction), with the OTHER user's profile.
  Future<List<ConnectionEdge>> myConnections() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client
        .from('connections')
        .select(
            'id, status, requester_id, addressee_id, requester:profiles!requester_id(*), addressee:profiles!addressee_id(*)')
        .or('requester_id.eq.$uid,addressee_id.eq.$uid')
        .eq('status', 'accepted')
        .order('updated_at', ascending: false);
    return (rows as List)
        .map((e) {
          final m = e as Map<String, dynamic>;
          final other = m['requester_id'] == uid ? m['addressee'] : m['requester'];
          if (other is! Map) return null;
          return ConnectionEdge(
            id: m['id'] as String,
            status: m['status'] as String,
            other: Profile.fromMap(other.cast<String, dynamic>()),
          );
        })
        .whereType<ConnectionEdge>()
        .toList();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../models/conversation.dart';
import '../models/profile.dart';

/// A direct-message thread paired with the OTHER participant's profile.
class DmThread {
  const DmThread({
    required this.id,
    required this.other,
    this.lastBody,
    this.lastAt,
    this.unread = 0,
  });

  final String id;
  final Profile other;
  final String? lastBody;
  final DateTime? lastAt;
  final int unread;
}

/// Reads/writes real 1:1 direct messages (`dm_threads` / `dm_messages`).
class DmRepository {
  SupabaseClient get _client => SupabaseConfig.client;
  String? get _uid => _client.auth.currentUser?.id;

  /// Returns the existing thread id for the pair (me, [otherId]), creating it
  /// if needed. Pair is stored canonically with user_a < user_b.
  Future<String> getOrCreateThread(String otherId) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    final a = uid.compareTo(otherId) < 0 ? uid : otherId;
    final b = uid.compareTo(otherId) < 0 ? otherId : uid;
    final existing = await _client
        .from('dm_threads')
        .select('id')
        .eq('user_a', a)
        .eq('user_b', b)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;
    final inserted = await _client
        .from('dm_threads')
        .insert({'user_a': a, 'user_b': b})
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  /// All my threads (with the other user + unread count), newest first.
  Future<List<DmThread>> fetchThreads() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client.rpc('my_dm_threads');
    return (rows as List).map((e) {
      final m = e as Map<String, dynamic>;
      return DmThread(
        id: m['thread_id'] as String,
        other: Profile(
          id: m['other_id'] as String,
          firstName: m['other_first'] as String?,
          lastName: m['other_last'] as String?,
          category: m['other_category'] as String?,
          avatarUrl: m['other_avatar'] as String?,
        ),
        lastBody: m['last_body'] as String?,
        lastAt: DateTime.tryParse(m['last_at'] as String? ?? '')?.toLocal(),
        unread: (m['unread'] as int?) ?? 0,
      );
    }).toList();
  }

  /// Mark [threadId] read up to now for the current user.
  Future<void> markRead(String threadId) async {
    await _client.rpc('mark_dm_read', params: {'p_thread': threadId});
  }

  /// Realtime: fire [onChange] whenever a new message lands in [threadId].
  RealtimeChannel subscribeThread(String threadId, void Function() onChange) {
    final ch = _client.channel('dm_thread_$threadId');
    ch
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'dm_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'thread_id',
            value: threadId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
    return ch;
  }

  /// Realtime: fire [onChange] on any new message in my threads (RLS-filtered).
  RealtimeChannel subscribeInbox(void Function() onChange,
      {String channel = 'dm_inbox'}) {
    final ch = _client.channel(channel);
    ch
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'dm_messages',
          callback: (_) => onChange(),
        )
        .subscribe();
    return ch;
  }

  Future<void> unsubscribe(RealtimeChannel ch) async {
    await _client.removeChannel(ch);
  }

  /// Messages in [threadId], oldest first, with `fromMe` resolved for me.
  Future<List<ChatMessage>> fetchMessages(String threadId) async {
    final uid = _uid;
    final rows = await _client
        .from('dm_messages')
        .select('id, sender_id, body, created_at')
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);
    return (rows as List).map((e) {
      final m = e as Map<String, dynamic>;
      return ChatMessage(
        id: m['id'] as String,
        fromMe: m['sender_id'] == uid,
        body: (m['body'] as String?) ?? '',
        timeLabel: _timeLabel(m['created_at'] as String?),
      );
    }).toList();
  }

  Future<void> sendMessage(String threadId, String body) async {
    final uid = _uid;
    if (uid == null) throw StateError('You are not signed in.');
    await _client.from('dm_messages').insert({
      'thread_id': threadId,
      'sender_id': uid,
      'body': body,
    });
  }

  String _timeLabel(String? iso) {
    final dt = DateTime.tryParse(iso ?? '')?.toLocal();
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

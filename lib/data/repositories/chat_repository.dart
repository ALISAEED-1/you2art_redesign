import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../models/conversation.dart';

/// Reads conversations / messages and sends new messages.
class ChatRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Conversation>> fetchConversations() async {
    final rows = await _client
        .from('conversations')
        .select()
        .order('sort_order', ascending: true);
    return (rows as List)
        .map((e) => Conversation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((e) => ChatMessage.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage(String conversationId, String body) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'from_me': true,
      'body': body,
      'time_label': 'Just Now',
      'sort_order': 999999,
    });
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../models/app_notification.dart';
import '../models/transaction.dart';

/// Reads notifications and transaction history.
class MiscRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  /// Count of the current user's own unread notifications (drives the bell badge).
  Future<int> unreadNotificationCount() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', uid)
        .eq('is_read', false);
    return (rows as List).length;
  }

  /// Marks the current user's notifications as read (clears the badge).
  Future<void> markNotificationsRead() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
  }

  Future<List<AppNotification>> fetchNotifications() async {
    final rows = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Transaction>> fetchTransactions() async {
    final rows = await _client
        .from('transactions')
        .select()
        .order('sort_order', ascending: true);
    return (rows as List)
        .map((e) => Transaction.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

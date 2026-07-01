import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../models/network_person.dart';

/// Reads the network directory (requests / connections / suggestions).
class NetworkRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<NetworkPerson>> fetchAll() async {
    final rows = await _client
        .from('network_people')
        .select()
        .order('sort_order', ascending: true);
    return (rows as List)
        .map((e) => NetworkPerson.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

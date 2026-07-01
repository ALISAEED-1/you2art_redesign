import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../models/talent.dart';

/// Reads the seeded talent / production-house directory.
class TalentRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Talent>> fetchTalents() async {
    final rows =
        await _client.from('talents').select().order('created_at');
    return (rows as List)
        .map((e) => Talent.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

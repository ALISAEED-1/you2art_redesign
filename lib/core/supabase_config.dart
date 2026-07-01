import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase connection setup.
///
/// NOTE: The backend (tables, auth, queries) is intentionally NOT wired up yet.
/// This file only establishes the client connection so the rest of the app can
/// start talking to Supabase later by simply calling [SupabaseConfig.client].
///
/// To finish the connection, drop your project's values into [_url] and
/// [_anonKey] below (find them in the Supabase dashboard under
/// Project Settings → API). Until then the app runs fine and skips init.
class SupabaseConfig {
  SupabaseConfig._();

  // ── Project credentials ─────────────────────────────────────────────────
  // You2Art project (region ap-south-1). These can be overridden at build time
  // with --dart-define=SUPABASE_URL=... / --dart-define=SUPABASE_ANON_KEY=...
  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ppzywqvgvwhisdhqwafs.supabase.co',
  );

  // Public "publishable" key — safe to ship in the client; RLS protects data.
  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_i3ZdQBkCC5H3Nnap9hPHfg_bRW0Nami',
  );

  /// Whether real credentials have been provided.
  static bool get isConfigured => _url.isNotEmpty && _publishableKey.isNotEmpty;

  /// Call once, before `runApp`, to establish the connection.
  ///
  /// If credentials are missing this is a no-op so local UI work isn't blocked.
  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint(
        'SupabaseConfig: skipping init — no SUPABASE_URL / SUPABASE_ANON_KEY '
        'provided yet. The connection scaffold is in place; add credentials '
        'in lib/core/supabase_config.dart to go live.',
      );
      return;
    }

    await Supabase.initialize(url: _url, publishableKey: _publishableKey);
    debugPrint('SupabaseConfig: connection established.');
  }

  /// Shared client handle for queries/auth once the backend is wired up.
  /// Throws if accessed before a successful [initialize].
  static SupabaseClient get client => Supabase.instance.client;
}

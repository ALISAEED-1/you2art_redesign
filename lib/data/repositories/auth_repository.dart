import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';

/// Thin wrapper around Supabase's phone-OTP auth.
///
/// Keeps the raw Supabase calls in one place so the rest of the app (providers,
/// screens) never touches `SupabaseClient` directly.
class AuthRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  /// The signed-in session, or null when logged out.
  Session? get currentSession => _client.auth.currentSession;

  /// The signed-in user, or null when logged out.
  User? get currentUser => _client.auth.currentUser;

  /// Emits whenever the auth state changes (sign-in, sign-out, token refresh).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sends a 6-digit SMS code to [phoneE164] (e.g. "+923001234567").
  ///
  /// Requires an SMS provider (Twilio / MessageBird / Vonage) to be configured
  /// in the Supabase dashboard under Auth → Providers → Phone.
  Future<void> sendOtp(String phoneE164) {
    return _client.auth.signInWithOtp(phone: phoneE164);
  }

  /// Verifies the [token] the user received over SMS for [phoneE164].
  Future<AuthResponse> verifyOtp({
    required String phoneE164,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phoneE164,
      token: token,
    );
  }

  /// Signs the current user out and clears the local session.
  Future<void> signOut() => _client.auth.signOut();
}

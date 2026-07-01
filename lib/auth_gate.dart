import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'data/repositories/profile_repository.dart';
import 'authorization/choose_category.dart';
import 'authorization/login.dart';
import 'home_page.dart';

/// Decides the start screen from the persisted Supabase session:
/// - no session            → Login
/// - session, no profile    → resume onboarding (Choose Category)
/// - session + full profile → Home
///
/// This is what stops the app from forcing login + the logo splash on every
/// launch for an already-signed-in user.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Widget> _destination = _resolve();

  // The Y2Art logo splash stays on screen for at least this long on every
  // launch, even when the session resolves instantly.
  static const Duration _minSplash = Duration(milliseconds: 1800);

  Future<Widget> _resolve() async {
    final start = DateTime.now();
    final dest = await _decide();
    final remaining = _minSplash - DateTime.now().difference(start);
    if (remaining > Duration.zero) await Future.delayed(remaining);
    return dest;
  }

  Future<Widget> _decide() async {
    if (!SupabaseConfig.isConfigured) return const LoginScreen();
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const LoginScreen();
    try {
      final profile = await ProfileRepository().fetchMyProfile();
      final complete = (profile?.firstName ?? '').trim().isNotEmpty;
      return complete ? const HomePage() : const ChooseCategoryScreen();
    } catch (_) {
      // If we can't reach the profile, still let the signed-in user in.
      return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _destination,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _splash(context);
        }
        return snapshot.data ?? const LoginScreen();
      },
    );
  }

  Widget _splash(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/y2logo.png',
          width: size.width * 0.45,
          height: size.height * 0.18,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
        ),
      ),
    );
  }
}

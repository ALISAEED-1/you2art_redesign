import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/casting_provider.dart';
import 'providers/post_provider.dart';
import 'providers/profile_provider.dart';
import 'auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Establish the Supabase connection (uses the You2Art project credentials in
  // lib/core/supabase_config.dart).
  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => CastingProvider()),
      ],
      child: MaterialApp(
        title: 'You2Art',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE52321)),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

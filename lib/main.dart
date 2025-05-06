// lib/main.dart

import 'package:flutter/material.dart';
import 'package:guild_client/screens/auth/auth_gate.dart';
import 'package:guild_client/screens/auth/login_screen.dart';
import 'package:guild_client/screens/auth/register_screen.dart';
import 'package:guild_client/viewmodels/auth_viewmodels.dart';
import 'package:provider/provider.dart';
import 'utils/orientations.dart';             // tu helper forceLandscape()
import 'services/api_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  forceLandscape();

  // Instancias principales
  final api  = ApiService();
  final auth = AuthViewModel(api);
  await auth.loadSession();     // intenta sesión guardada

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: const GuildClientApp(),
    ),
  );
}

class GuildClientApp extends StatelessWidget {
  const GuildClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Guild Client',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge:  TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      routes: {
        '/login':    (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
      home: const AuthGate(),   // decide Login o MainNavScreen
    );
  }
}

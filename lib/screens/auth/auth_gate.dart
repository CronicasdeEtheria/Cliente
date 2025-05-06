import 'package:flutter/material.dart';
import 'package:guild_client/viewmodels/auth_viewmodels.dart';
import 'package:provider/provider.dart';
import '../main_nav_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    if (!auth.isLogged) {
      return const LoginScreen();
    }
    return const MainNavScreen();
  }
}

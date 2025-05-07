// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:guild_client/viewmodels/auth_viewmodels.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _id = '', _pass = '';
  bool _loading = false;
  String? _error;

  final accent = const Color(0xffff8800);

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xff1b1b1b),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 1.3),
        ),
        labelStyle: const TextStyle(color: Colors.white60),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff101010), Color(0xff000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Card(
              color: const Color(0xff202020),
              elevation: 12,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // escudo
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: accent.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2)
                          ],
                        ),
                        child: const Icon(Icons.shield,
                            color: Colors.black, size: 34),
                      ),
                      const SizedBox(height: 20),
                      Text('Iniciar sesión',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: accent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 22),
                      TextFormField(
                        decoration: _dec('Email o usuario'),
                        onSaved: (v) => _id = v!.trim(),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        decoration: _dec('Contraseña'),
                        obscureText: true,
                        onSaved: (v) => _pass = v!.trim(),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 22),
                      if (_error != null)
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.black,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
 onPressed: _loading
  ? null
  : () async {
      if (!_formKey.currentState!.validate()) return;
      _formKey.currentState!.save();
      setState(() => _loading = true);
      final err = await auth.login(_id, _pass);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = err;
      });
      if (err == null) {
        // Login OK → navegar a MainNavScreen
        Navigator.pushReplacementNamed(context, '/');
      }
    },

                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black),
                                )
                              : const Text('Entrar'),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/register'),
                        style: TextButton.styleFrom(foregroundColor: accent),
                        child:
                            const Text('Crear cuenta', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

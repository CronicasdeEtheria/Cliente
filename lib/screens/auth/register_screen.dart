// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:guild_client/models/race.dart';
import 'package:guild_client/services/api_service.dart';
import 'package:guild_client/viewmodels/auth_viewmodels.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _user = '', _email = '', _pass = '';
  int _raceIdx = 0;
  bool _loading = false;
  String? _error;
  late Future<List<Race>> _racesFut;
  List<Race> _races = [];

  final accent = const Color(0xffff8800);

  @override
  void initState() {
    super.initState();
    _racesFut = context.read<ApiService>().fetchRaces();
  }

  String? get _raceId => _races.isEmpty ? null : _races[_raceIdx].id;

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

  void _prevRace() {
    setState(() => _raceIdx = (_raceIdx - 1 + _races.length) % _races.length);
  }

  void _nextRace() {
    setState(() => _raceIdx = (_raceIdx + 1) % _races.length);
  }

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
        child: LayoutBuilder(
          builder: (_, constraints) {
            final wide = constraints.maxWidth > 600;

            // ---------- FORM CARD ----------
            Widget formCard = Card(
              color: const Color(0xff202020),
              elevation: 12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!wide) _header(),
                      const SizedBox(height: 18),
                      TextFormField(
                        decoration: _dec('Usuario'),
                        onSaved: (v) => _user = v!.trim(),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Obligatorio' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: _dec('Email'),
                        onSaved: (v) => _email = v!.trim(),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Obligatorio' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: _dec('Contraseña'),
                        obscureText: true,
                        onSaved: (v) => _pass = v!.trim(),
                        validator: (v) =>
                            (v == null || v.length < 4) ? 'Mín. 4 caracteres' : null,
                      ),
                      const SizedBox(height: 18),
                      if (_error != null)
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _loading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                if (_raceId == null) {
                                  setState(() => _error = 'Selecciona una raza');
                                  return;
                                }
                                _formKey.currentState!.save();
                                setState(() {
                                  _loading = true;
                                  _error = null;
                                });
                                final err = await auth.register(
                                    _user, _email, _pass, _raceId!);
                                if (!mounted) return;
                                setState(() {
                                  _loading = false;
                                  _error = err;
                                });
                              },
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : const Text('Registrar', style: TextStyle(fontSize: 15)),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white70),
                        child: const Text('Ya tengo cuenta',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            );

            // ---------- RACE VIEWER ----------
            Widget raceViewer = FutureBuilder<List<Race>>(
              future: _racesFut,
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.white));
                }
                _races = snap.data!;
                // asegúrate de estar dentro de rango
                _raceIdx = _raceIdx.clamp(0, _races.length - 1);
                final r = _races[_raceIdx];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: accent, width: 3),
                              ),
                              child: Image.asset(
                                'assets/races/${r.id}.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left, size: 40),
                              color: Colors.white70,
                              onPressed: _prevRace,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right, size: 40),
                              color: Colors.white70,
                              onPressed: _nextRace,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      r.displayName,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.id,
                      style: const TextStyle(fontSize: 11, color: Colors.white60),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            );

            // ---------- LAYOUT PRINCIPAL ----------
            return Padding(
              padding: const EdgeInsets.all(24),
              child: wide
                  ? Row(
                      children: [
                        Expanded(flex: 3, child: formCard),
                        const SizedBox(width: 28),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _header(),
                              const SizedBox(height: 16),
                              Expanded(child: raceViewer),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _header(),
                        const SizedBox(height: 24),
                        formCard,
                        const SizedBox(height: 24),
                        SizedBox(height: 280, child: raceViewer),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _header() => Column(
        children: [
          Container(
            width: 64,
            height: 64,
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
            child: const Icon(Icons.shield, color: Colors.black, size: 32),
          ),
          const SizedBox(height: 12),
          Text('Elige tu linaje',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: accent)),
        ],
      );
}

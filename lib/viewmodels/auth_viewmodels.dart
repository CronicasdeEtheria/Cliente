// lib/viewmodels/auth_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService api;

  String? _uid;
  String? _token;
  String? _username;
  String? _raceId;

  bool get isLogged => _uid != null && _token != null;
  String get uid     => _uid!;                // <-- Getter expuesto para uid
  String get username => _username ?? '';
  String get raceId   => _raceId   ?? '';
  
  AuthViewModel(this.api);

  /// Carga la sesión guardada (uid, token, username, raceId).
  Future<void> loadSession() async {
    final sp = await SharedPreferences.getInstance();
    _uid      = sp.getString('uid');
    _token    = sp.getString('token');
    _username = sp.getString('username');
    _raceId   = sp.getString('raceId');
    if (isLogged) {
      api.setAuth(uid: _uid!, token: _token!);
    }
    notifyListeners();
  }

  /// Inicio de sesión con identificador (usuario o email) + contraseña.
  /// Almacena uid, token, username y raceId, y los persiste.
  Future<String?> login(String identifier, String pass) async {
    final resp = await api.login(identifier, pass);
    if (resp['ok'] == true) {
      _uid   = resp['uid']  as String?;
      _token = resp['token']as String?;
      api.setAuth(uid: _uid!, token: _token!);

      // Opcional: cargar perfil para sacar raceId y username
      final profile = await api.getUserProfile();
      _username = profile['username'] as String?;
      _raceId   = profile['race']    as String?;

      final sp = await SharedPreferences.getInstance();
      await sp
        ..setString('uid', _uid!)
        ..setString('token', _token!)
        ..setString('username', _username ?? '')
        ..setString('raceId', _raceId ?? '');
      notifyListeners();
      return null;
    }
    return resp['error'] as String? ?? 'Error desconocido';
  }

  /// Registro + autologin. Recibe usuario, email, contraseña y raza.
  Future<String?> register(
    String user,
    String email,
    String pass,
    String race,
  ) async {
    final resp = await api.register(user, email, pass, race);
    if (resp['ok'] == true) {
      // Después de registrar, nos logeamos automáticamente:
      return await login(email, pass);
    }
    return resp['error'] as String? ?? 'Error desconocido';
  }

  /// Elimina sesión y limpia almacenamiento.
  Future<void> logout() async {
    _uid = _token = _username = _raceId = null;
    final sp = await SharedPreferences.getInstance();
    await sp
      ..remove('uid')
      ..remove('token')
      ..remove('username')
      ..remove('raceId');
    notifyListeners();
  }

  /// Opcional: recarga explícita del perfil (por si cambian datos).
  Future<void> refreshProfile() async {
    if (!isLogged) return;
    final profile = await api.getUserProfile();
    _username = profile['username'] as String?;
    _raceId   = profile['race']    as String?;
    notifyListeners();
  }
}

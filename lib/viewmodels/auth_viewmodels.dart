import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService api;
  String? uid;
  String? token;
  bool get isLogged => uid != null && token != null;

  AuthViewModel(this.api);

  // Carga token persistente (opcional)
  Future<void> loadSession() async {
    final sp = await SharedPreferences.getInstance();
    uid   = sp.getString('uid');
    token = sp.getString('token');
    if (isLogged) api.setAuth(uid: uid!, token: token!);
    notifyListeners();
  }

Future<String?> login(String idOrEmail, String pass) async {
  final resp = await api.login(idOrEmail, pass);
    if (resp['ok'] == true) {
      uid   = resp['uid'];
      token = resp['token'];
      api.setAuth(uid: uid!, token: token!);

      final sp = await SharedPreferences.getInstance();
      await sp.setString('uid', uid!);
      await sp.setString('token', token!);

      notifyListeners();
      return null; // éxito
    }
    return resp['error'] ?? 'Error desconocido';
  }

Future<String?> register(
  String user,
  String email,
  String pass,
  String race,
) async {
  final resp = await api.register(user, email, pass, race);
  if (resp['ok'] == true) {
    return await login(user, pass);           // autologin
  }
  return resp['error'] ?? 'Error desconocido';
}

  Future<void> logout() async {
    uid = token = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove('uid');
    await sp.remove('token');
    notifyListeners();
  }
}

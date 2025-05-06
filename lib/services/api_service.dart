// lib/services/api_service.dart
//
// Versión completa y revisada: incluye manejo seguro de JSON, registro con
// usuario‑email‑password‑race y envío automático de uid/token en cabeceras
// para rutas protegidas.

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/building.dart';
import '../models/unit.dart';
import '../models/race.dart';
import '../models/guild.dart';
import '../models/message.dart';

class ApiService {
  final String baseUrl;
  String? _uid;
  String? _token;

  ApiService({this.baseUrl = 'http://10.0.2.2:8080'});

  // ── AUTENTICACIÓN ────────────────────────────────────────────────
  void setAuth({required String uid, required String token}) {
    _uid = uid;
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_uid != null) 'uid': _uid!,
        if (_token != null) 'token': _token!,
      };

  Map<String, dynamic> _safeJson(http.Response resp) {
    try {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return {'ok': false, 'error': resp.body};
    }
  }

  Future<Map<String, dynamic>> register(
    String user,
    String email,
    String pass,
    String race,
  ) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': user,
        'email': email,
        'password': pass,
        'race': race,
      }),
    );
    return _safeJson(resp);
  }
Future<Map<String, dynamic>> login(String identifier, String pass) async {
  final resp = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'identifier': identifier, 'password': pass}),
  );
  return _safeJson(resp);
}
  // ── ESTADÍSTICAS DEL USUARIO (recursos + edificios) ────────────────
  Future<Map<String, dynamic>> fetchUserStats() async {
    final resp =
        await http.post(Uri.parse('$baseUrl/user/stats'), headers: _headers);

    // Manejo seguro por si el servidor devuelve texto plano ante un error
    final json = _safeJson(resp);
    if (json['ok'] != true) {
      throw Exception(json['error'] ?? 'Error al obtener stats');
    }
    return json;
  }


  // ── PÚBLICAS ─────────────────────────────────────────────────────
  Future<List<Guild>> fetchGuilds() async {
    final resp = await http.get(Uri.parse('$baseUrl/guild/list'));
    final data = jsonDecode(resp.body) as List;
    return data.map((e) => Guild.fromJson(e)).toList();
  }

  Future<List<dynamic>> fetchGuildRanking() async =>
      jsonDecode((await http.get(Uri.parse('$baseUrl/guild/ranking'))).body)
          as List;

  Future<Uint8List> fetchGuildImage(String guildId) async =>
      (await http.get(Uri.parse('$baseUrl/guild/image/$guildId'))).bodyBytes;

  Future<List<Message>> fetchChatHistory() async {
    final resp = await http.get(Uri.parse('$baseUrl/chat/global/history'));
    final data = jsonDecode(resp.body) as List;
    return data.map((e) => Message.fromJson(e)).toList();
  }

  Future<List<dynamic>> fetchUserRanking() async =>
      jsonDecode((await http.get(Uri.parse('$baseUrl/ranking'))).body) as List;

  Future<List<dynamic>> fetchOnlineUsers() async =>
      jsonDecode((await http.get(Uri.parse('$baseUrl/online_users'))).body)
          as List;

  // ── ADMIN (sin auth) ─────────────────────────────────────────────
  Future<List<dynamic>> fetchAdminUsers() async =>
      jsonDecode((await http.get(Uri.parse('$baseUrl/admin/users'))).body)
          as List;

  Future<List<dynamic>> fetchAdminConnected() async =>
      jsonDecode((await http.get(Uri.parse('$baseUrl/admin/connected_users')))
              .body) as List;

  Future<DateTime> fetchServerTime() async {
    final resp = await http.get(Uri.parse('$baseUrl/admin/server_time'));
    return DateTime.parse(
        (jsonDecode(resp.body) as Map<String, dynamic>)['server_time']);
  }

  Future<List<dynamic>> fetchRaceStats() async =>
      jsonDecode((await http.get(Uri.parse('$baseUrl/admin/raza_stats'))).body)
          as List;

  // ── PROTEGIDAS (uid+token) ───────────────────────────────────────
  Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/user/update_fcm'),
          headers: _headers, body: jsonEncode({'fcmToken': fcmToken})));

  Future<Map<String, dynamic>> getUserProfile() async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/user/profile'),
          headers: _headers));

  Future<Map<String, dynamic>> collectResources() async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/user/collect'),
          headers: _headers));

  Future<Map<String, dynamic>> cancelConstruction(String buildId) async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/build/cancel'),
          headers: _headers, body: jsonEncode({'buildId': buildId})));

  Future<Map<String, dynamic>> startTraining(String unitId, int qty) async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/train/start'),
          headers: _headers,
          body: jsonEncode({'unitId': unitId, 'quantity': qty})));

  Future<Map<String, dynamic>> cancelTraining(String trainId) async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/train/cancel'),
          headers: _headers, body: jsonEncode({'trainId': trainId})));

  Future<Map<String, dynamic>> syncQueues(List<dynamic> queues) async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/sync/queues'),
          headers: _headers, body: jsonEncode({'queues': queues})));

  Future<Map<String, dynamic>> randomBattle() async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/battle/random'),
          headers: _headers));

  Future<List<dynamic>> fetchBattleHistory() async =>
      jsonDecode((await http.post(Uri.parse('$baseUrl/battle/history'),
              headers: _headers))
          .body) as List;

  Future<Map<String, dynamic>> createGuild(String name) async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/guild/create'),
          headers: _headers, body: jsonEncode({'name': name})));

  Future<Map<String, dynamic>> joinGuild(String guildId) async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/guild/join'),
          headers: _headers, body: jsonEncode({'guildId': guildId})));

  Future<Map<String, dynamic>> leaveGuild() async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/guild/leave'),
          headers: _headers));

  Future<Map<String, dynamic>> getGuildInfo(String guildId) async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/guild/info'),
          headers: _headers, body: jsonEncode({'guildId': guildId})));

  // (uploadGuildImage pendiente)

  Future<Map<String, dynamic>> kickMember(String memberId) async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/guild/kick_member'),
          headers: _headers, body: jsonEncode({'memberId': memberId})));

  Future<Map<String, dynamic>> transferLeadership(String memberId) async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/guild/transfer_leadership'),
          headers: _headers, body: jsonEncode({'memberId': memberId})));

  Future<Map<String, dynamic>> updateGuildInfo(
          Map<String, dynamic> info) async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/guild/update_info'),
          headers: _headers, body: jsonEncode(info)));

  Future<List<Building>> fetchUserBuildings() async {
    final resp =
        await http.post(Uri.parse('$baseUrl/user/stats'), headers: _headers);
    final json = _safeJson(resp);
    final data = (json['buildings'] ?? []) as List;
    return data.map((e) => Building.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> fetchUserBattleStats() async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/user/battle_stats'),
          headers: _headers));

  // ── CATÁLOGOS (opcionales, si los sirves desde servidor) ───────────
  Future<List<Unit>> fetchUnits() async {
    final resp = await http.get(Uri.parse('$baseUrl/unit/list'));
    final list = jsonDecode(resp.body) as List;
    return list.map((e) => Unit.fromJson(e)).toList();
  }

  Future<List<Race>> fetchRaces() async {
    final resp = await http.get(Uri.parse('$baseUrl/race/list'));
    final list = jsonDecode(resp.body) as List;
    return list.map((e) => Race.fromJson(e)).toList();
  }
}

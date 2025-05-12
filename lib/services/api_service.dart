// lib/services/api_service.dart
//
// Versión completa y revisada: incluye manejo seguro de JSON, registro con
// usuario‑email‑password‑race y envío automático de uid/token en cabeceras
// para rutas protegidas.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/building.dart';
import '../models/unit.dart';
import '../models/race.dart';
import '../models/guild.dart';
import '../models/message.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  final String baseUrl;
  String? _uid;
  String? _token;

 ApiService({String? baseUrl})
      : baseUrl = baseUrl ??
          dotenv.env['BASE_URL'] ??
          'http://localhost:3090';

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
Future<Map<String, dynamic>> uploadGuildImage(
    String guildId,
    File imageFile,
  ) async {
    final uri = Uri.parse('$baseUrl/guild/upload_image');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers)
      ..fields['guild_id'] = guildId;

    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final parts = mimeType.split('/');
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType(parts[0], parts[1]),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'status': 'error', 'error': response.body};
    }
  }

  Future<Uint8List> fetchGuildImage(String guildId) async =>
      (await http.get(Uri.parse('$baseUrl/guild/image/$guildId'))).bodyBytes;

/// Envía un mensaje al chat global.
Future<Map<String, dynamic>> sendGlobalMessage(String message) async {
  final resp = await http.post(
    Uri.parse('$baseUrl/chat/global/send'),
    headers: _headers,
    body: jsonEncode({'message': message}),
  );
  return _safeJson(resp);
}

/// Recupera el historial (hasta 50 mensajes) del chat global.
Future<List<Message>> fetchChatHistory() async {
  final resp = await http.get(Uri.parse('$baseUrl/chat/global/history'));
  final data = jsonDecode(resp.body) as List;
  return data.map((e) => Message.fromJson(e)).toList();
}


Future<List<dynamic>> fetchUserRanking({
  String type = 'elo',
  String? race,
  int limit = 20,
}) async {
  // Construye la URI con query parameters
  final uri = Uri.parse('$baseUrl/ranking').replace(queryParameters: {
    'type': type,
    if (race != null) 'race': race,
    'limit': limit.toString(),
  });

  final response = await http.get(uri);
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as List;
  } else {
    throw Exception('Error ${response.statusCode} al cargar ranking');
  }
}

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

Future<Map<String, dynamic>> cancelConstruction(String id) async {
  final resp = await http.post(
    Uri.parse('$baseUrl/build/cancel'),
    headers: _headers,
    body: jsonEncode({'id': id}),
  );
  return _safeJson(resp);
}

Future<Map<String, dynamic>> startTraining({
  required String unitType,
  required int quantity,
}) async {
  final uri = Uri.parse('$baseUrl/train/start');
  final response = await http.post(
    uri,
    headers: _headers,              // <— incluye content-type, uid y token
    body: jsonEncode({
  'uid': _uid,                 // vuelve a ponerlo
      'unit_type': unitType,
      'quantity': quantity,
    }),
  );

  if (response.statusCode != 200) {
    // ...
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}
Future<Map<String, dynamic>> fetchQueueStatus() async {
  final resp = await http.post(
    Uri.parse('$baseUrl/sync/queues'),
    headers: _headers,
    body: jsonEncode({'uid': _uid}),
  );
  return _safeJson(resp);
}

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

Future<Map<String, dynamic>> createGuild(
  String name, {
  String? defaultIcon,
}) async {
  final body = {
    'name': name,
    if (defaultIcon != null) 'default_icon': defaultIcon,
  };
  final resp = await http.post(
    Uri.parse('$baseUrl/guild/create'),
    headers: _headers,
    body: jsonEncode(body),
  );
  return _safeJson(resp);
}

Future<Map<String, dynamic>> joinGuild(String guildId) async {
  final uri = Uri.parse('$baseUrl/guild/join');
  final response = await http.post(
    uri,
    headers: _headers,  
    body: jsonEncode({
      'uid': _uid,           
      'guild_id': guildId,    
    }),
  );
  return _safeJson(response);
}


Future<Map<String, dynamic>> leaveGuild() async {
  final resp = await http.post(
    Uri.parse('$baseUrl/guild/leave'),
    headers: _headers,       
    body: jsonEncode({       
      'uid': _uid,
    }),
  );
  return _safeJson(resp);
}


  Future<Map<String, dynamic>> getGuildInfo(String guildId) async =>
      _safeJson(await http.post(Uri.parse('$baseUrl/guild/info'),
          headers: _headers, body: jsonEncode({'guild_id': guildId})));

  Future<Map<String, dynamic>> startConstruction(String buildId, int level) async =>
    _safeJson(await http.post(Uri.parse('$baseUrl/build/start'),
        headers: _headers,
        body: jsonEncode({'buildId': buildId, 'targetLevel': level})));


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
  Future<Map<String, dynamic>> fetchBuildQueue() async =>
    _safeJson(await http.post(Uri.parse('$baseUrl/build/status'),
        headers: _headers));


Future<List<dynamic>> fetchBattleReports() async {
  final resp = await http.post(
    Uri.parse('$baseUrl/battle/history'),
    headers: _headers,
    body: jsonEncode({'uid': _uid}),
  );
  return jsonDecode(resp.body) as List<dynamic>;
}


Future<List<dynamic>> fetchUserArmy() async {
  final resp = await http.post(
    Uri.parse('$baseUrl/battle/army'),
    headers: _headers,
    body: jsonEncode({'uid': _uid}),
  );
  return jsonDecode(resp.body) as List<dynamic>;
}

Future<Map<String, dynamic>> randomBattleWithArmy(
    Map<String, int> army) async {
  final resp = await http.post(
    Uri.parse('$baseUrl/battle/random'),
    headers: _headers,
    body: jsonEncode({
      'uid': _uid,
      'army': army,
    }),
  );
  return _safeJson(resp);
}

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

// lib/models/building.dart
//
// Modelo de edificio para el cliente.
//
// - Lee `id` y `level` del JSON recibido desde el servidor.
// - Si el JSON trae `name`, lo usa.
// - Si no, consulta un mapa local `buildingNames` con nombres “bonitos”.
// - Como último recurso, devuelve el propio `id`.


class Building {
  final String id;
  final String name;
  final int    level;

  Building.fromJson(Map<String, dynamic> j)
      : id    = j['id']    as String,
        level = j['level'] as int,
        name  = _resolveName(j);

  // ────────────────────────────────────────────────────────────────────
  static const Map<String, String> _buildingNames = {
    'townhall'  : 'Ayuntamiento',
    'warehouse' : 'Almacén',
    'barracks'  : 'Cuartel',
    'lumbermill': 'Aserradero',
    'stonemine' : 'Mina de piedra',
    'farm'      : 'Granja',
    'coliseo'   : 'Coliseo',
  };

  static String _resolveName(Map<String, dynamic> j) {
    // 1) El servidor ya trae 'name'
    final jsonName = j['name'];
    if (jsonName is String && jsonName.isNotEmpty) return jsonName;

    // 2) Busca en el mapa local
    final id = j['id'] as String;
    if (_buildingNames.containsKey(id)) return _buildingNames[id]!;

    // 3) Fallback: Capitaliza el id
    return id.isNotEmpty
        ? id[0].toUpperCase() + id.substring(1)
        : 'Desconocido';
  }
}

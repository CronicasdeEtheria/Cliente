// lib/screens/home_screen.dart
//
// • El mapa llena toda la pantalla.
// • Barra de recursos centrada arriba (muestra +prod/h y capacidad al pulsar).
// • Todos los edificios se ven (si el server no devuelve alguno, se crea Lv0).
// • Cada edificio abre el sheet `showBuildingActions()` (en widgets/building_actions_sheet.dart).
// • Etiqueta del edificio sobre la imagen.

import 'package:flutter/material.dart';
import 'package:guild_client/models/building.dart';
import 'package:guild_client/screens/homescreen/bulding_action_sheet.dart';
import 'package:guild_client/services/api_service.dart';
import 'package:provider/provider.dart';



/// Posiciones proporcionales (x,y)
const Map<String, Offset> kBuildingPositions = {
  'townhall':  Offset(.20, .40),
  'farm':      Offset(.45, .35),
  'lumbermill':Offset(.70, .45),
  'stonemine': Offset(.35, .52),
  'warehouse': Offset(.55, .58),
  'barracks':  Offset(.80, .38),
  'coliseo':   Offset(.10, .33),
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _statsFut;

  @override
  void initState() {
    super.initState();
    _statsFut = context.read<ApiService>().fetchUserStats();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mapW = size.width;
    final mapH = size.height;

    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFut,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final resources = Map<String, int>.from(snap.data!['resources']);
        final listFromSrv = (snap.data!['buildings'] as List)
            .map((e) => Building.fromJson(e))
            .toList();

// Sustituye el bloque que rellena la lista de edificios
final buildings = [
  for (final id in kBuildingPositions.keys)
    listFromSrv.firstWhere(
      (b) => b.id == id,
      // ⬇️ usamos fromJson para fabricar un edificio vacío
      orElse: () => Building.fromJson({'id': id, 'level': 0, 'name': id}),
    ),
];


        return Stack(
          children: [
            // Mapa
            Positioned.fill(
              child: Image.asset('assets/images/terrain_bg.png',
                  fit: BoxFit.cover),
            ),

            // Barra de recursos
            Positioned(
              top: MediaQuery.of(context).padding.top + 6,
              left: 0,
              right: 0,
              child: Center(child: _ResourceBar(resources: resources)),
            ),

            // Edificios
            ...buildings.map((b) {
              final pos = kBuildingPositions[b.id]!;
              final left = pos.dx * mapW - 36;
              final top  = pos.dy * mapH - 36;

              return _BuildingWidget(
                left: left,
                top: top,
                building: b,
              );
            }),
          ],
        );
      },
    );
  }
}

// ═════════════════════ Helpers ══════════════════════════════════════

// Barra de recursos + prod/h + capacidad tooltip
class _ResourceBar extends StatelessWidget {
  final Map<String, int> resources;
  const _ResourceBar({required this.resources});

  // Dummy numbers; reemplaza con valores reales obtenidos del servidor.
  static const prodH = {'food': 12, 'wood': 10, 'stone': 9, 'gold': 4};
  static const cap   = {'food': 4000, 'wood': 4000, 'stone': 4000, 'gold': 4000};

  @override
  Widget build(BuildContext context) {
    Widget _tile(String key, String emoji) => GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(seconds: 2),
            content: Text('Capacidad máx. $emoji: ${cap[key]}'),
          )),
          child: Column(
            children: [
              Text('$emoji ${resources[key] ?? 0}',
                  style: const TextStyle(fontSize: 11, color: Colors.white)),
              Text('+${prodH[key]} /h',
                  style: const TextStyle(fontSize: 8, color: Colors.white70)),
            ],
          ),
        );

    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _tile('food',  '🍖'),
          _tile('wood',  '🪵'),
          _tile('stone', '🪨'),
          _tile('gold',  '🪙'),
        ],
      ),
    );
  }
}

// Widget de edificio
class _BuildingWidget extends StatelessWidget {
  final double left;
  final double top;
  final Building building;
  const _BuildingWidget({
    required this.left,
    required this.top,
    required this.building,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: 72,
      child: GestureDetector(
        onTap: () => showBuildingActions(context, building),
        child: Column(
          children: [
            // Etiqueta
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_names[building.id] ?? building.id} Lv${building.level}',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            _SafeImage(path: 'assets/buildings/${building.id}.png'),
          ],
        ),
      ),
    );
  }
}

const _names = {
  'townhall': 'Ayuntamiento',
  'farm': 'Granja',
  'lumbermill': 'Aserradero',
  'stonemine': 'Mina',
  'warehouse': 'Almacén',
  'barracks': 'Cuartel',
  'coliseo': 'Coliseo',
};

// Imagen con placeholder
class _SafeImage extends StatelessWidget {
  final String path;
  const _SafeImage({required this.path});
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: 72,
      height: 72,
      errorBuilder: (_, __, ___) => Container(
        width: 72,
        height: 72,
        color: Colors.grey[800],
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported,
            size: 24, color: Colors.white38),
      ),
    );
  }
}

// ══════════════════ Extension para clone opcional ══════════════════
extension BuildingX on Building {
  Building copyWith({String? id, String? name, int? level}) => Building(
        id: id ?? this.id,
        name: name ?? this.name,
        level: level ?? this.level,
      );
}

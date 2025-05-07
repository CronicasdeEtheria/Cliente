import 'package:flutter/material.dart';
import 'package:guild_client/models/building.dart';
import 'package:guild_client/screens/homescreen/bulding_action_sheet.dart';


class BuildingLayer extends StatelessWidget {
    final void Function(Building) onTapBuilding;
  final List<Building> buildings;
  final double mapW;
  final double mapH;
  final Map<String, Offset> positions;

  const BuildingLayer({
    super.key,
    required this.buildings,
    required this.mapW,
    required this.mapH,
    required this.positions,
    required this.onTapBuilding
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: buildings.map((b) {
        final pos = positions[b.id]!;
        final left = pos.dx * mapW - 36;
        final top  = pos.dy * mapH - 36;

        return Positioned(
          left: left,
          top: top,
          width: 72,
          child: GestureDetector(
           onTap: () => onTapBuilding(b),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    '${_names[b.id] ?? b.id} Lv${b.level}',
                    style:
                        const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
                Image.asset(
                  'assets/buildings/${b.id}.png',
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
                ),
              ],
            ),
          ),
        );
      }).toList(),
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

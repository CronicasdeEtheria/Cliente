// lib/widgets/building_actions_sheet.dart
import 'package:flutter/material.dart';
import 'package:guild_client/models/building.dart';


Future<void> showBuildingActions(BuildContext ctx, Building b) {
  final isBarracks = b.id == 'barracks';

  return showModalBottomSheet(
    context: ctx,
    backgroundColor: const Color(0xff202020),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_names[b.id] ?? b.id} (Lv${b.level})',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.upgrade, color: Colors.white),
            title:
                const Text('Mejorar', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              // TODO: launch upgrade screen
            },
          ),
          if (isBarracks)
            ListTile(
              leading: const Icon(Icons.safety_check, color: Colors.white),
              title: const Text('Entrenar unidades',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: launch training screen
              },
            ),
        ],
      ),
    ),
  );
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

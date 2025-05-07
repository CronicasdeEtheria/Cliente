// lib/screens/homescreen/home_screen.dart

import 'package:flutter/material.dart';
import 'package:guild_client/screens/barracks_screen.dart';
import 'package:guild_client/screens/homescreen/bulding_action_sheet.dart';
import 'package:provider/provider.dart';

import '../../models/building.dart';
import '../../services/api_service.dart';
import 'widget/building_layer.dart';
import 'widget/construction_queue_panel.dart';
import 'widget/resource_bar.dart';

/// Posición relativa de cada edificio (x,y 0‑1)
const Map<String, Offset> kPositions = {
  'townhall':   Offset(.20, .40),
  'farm':       Offset(.45, .35),
  'lumbermill': Offset(.70, .45),
  'stonemine':  Offset(.35, .52),
  'warehouse':  Offset(.55, .58),
  'barracks':   Offset(.80, .38),
  'coliseo':    Offset(.10, .33),
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
    _loadStats();
  }

  void _loadStats() {
    _statsFut = context.read<ApiService>().fetchUserStats();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFut,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        final data = snap.data!;
        // ─── Depuración ───
        print('🏗️ /user/stats response: $data');

        // ─── Recursos y balance ───
        final res    = Map<String, int>.from(data['resources']);
        final prodH  = Map<String, int>.from(data['prod_hour']);
        final cap    = Map<String, int>.from(data['capacity']);

        // ─── Construcción de la lista de edificios ───
        final fromSrvRaw = data['buildings'] as List;
        print('🏗️ raw buildings array: $fromSrvRaw');

        final fromSrv = fromSrvRaw.map((e) {
          print('🏗️ building json entry: $e');
          return Building.fromJson(e as Map<String, dynamic>);
        }).toList();

        final buildings = [
          for (final id in kPositions.keys)
            fromSrv.firstWhere(
              (b) => b.id == id,
              orElse: () {
                print('🏗️ building "$id" missing, defaulting to Lv1');
                return Building.fromJson({'id': id, 'level': 1, 'name': id});
              },
            )
        ];

        // ─── UI ───────────────────────────────
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/terrain_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 6,
              left: 0,
              right: 0,
              child: Center(
                child: ResourceBar(
                  resources: res,
                  prodHour: prodH,
                  capacity: cap,
                ),
              ),
            ),
BuildingLayer(
  buildings: buildings,
  mapW: size.width,
  mapH: size.height,
  positions: kPositions,
  onTapBuilding: (b) => showBuildingActions(
    context,
    b,
    onUpgradeOk: _loadStats,
    onTrain: (ctx, building) {
      // Si es barracks o coliseo, abre la pantalla de entrenamiento
      Navigator.pop(ctx); // cierra el diálogo
showBarracksDialog(ctx);
    },
  ),
),
            const ConstructionQueuePanel(),
          ],
        );
      },
    );
  }
}

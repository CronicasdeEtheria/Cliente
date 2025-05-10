import 'package:flutter/material.dart';
import 'package:guild_client/data/building_catalogl.dart';
import 'package:guild_client/models/building.dart';
import 'package:guild_client/screens/homescreen/widget/pvp_dialog.dart';
import 'package:guild_client/services/api_service.dart';
import 'package:provider/provider.dart';

typedef TrainingNav = void Function(BuildContext ctx, Building barracks);

Future<void> showBuildingActions(
  BuildContext ctx,
  Building b, {
  required VoidCallback onUpgradeOk,
  TrainingNav? onTrain,
}) => showDialog(
      context: ctx,
      barrierColor: Colors.black54,
      builder: (_) => _ActionDialog(
            building: b,
            onTrain: onTrain,
            onUpgradeOk: onUpgradeOk,
          ),
    );

class _ActionDialog extends StatefulWidget {
  final VoidCallback onUpgradeOk;
  final Building building;
  final TrainingNav? onTrain;
  const _ActionDialog({required this.building, this.onTrain, required this.onUpgradeOk});
  @override
  State<_ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<_ActionDialog> {
  bool _loading = false;
  String? _error;
  @override
  Widget build(BuildContext context) {
    final b = widget.building;
    final d = buildingCatalog[b.id]!;
    final nextLv = b.level + 1;
    final cost = _costForLevel(d, nextLv);
    final timeSecs = _timeForLevel(d, nextLv);
    final prodNow = _production(b.id, b.level);
    final prodNext = _production(b.id, nextLv);
    final capNow = _capacity(b.id, b.level);
    final capNext = _capacity(b.id, nextLv);
    final size = MediaQuery.of(context).size;
    final double maxW = (size.width * .60).clamp(0.0, 500.0);
    return Dialog(
      backgroundColor: const Color(0xff202020),
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * .2, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: maxW,
        height: 220,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xff262626),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Text(
                '${_names[b.id] ?? b.id}  Lv${b.level}' +
                (b.id != 'coliseo' ? ' → Lv$nextLv' : ''),
                style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _costRow('🪵', cost['wood']!),
                          _costRow('🪨', cost['stone']!),
                          _costRow('🍖', cost['food']!),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.timer, size: 16, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(_prettyTime(timeSecs), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _infoRow('Producción/h', prodNow?.toString() ?? '-', prodNext?.toString() ?? '-'),
                          const SizedBox(height: 8),
                          _infoRow('Capacidad', capNow?.toString() ?? '-', capNext?.toString() ?? '-'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  if (b.id == 'coliseo') ...[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black),
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.pop(context);
                                showPvPDialog(context);
                              },
                        child: const Text('Pelear'),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black),
                        onPressed: _loading
                            ? null
                            : () async {
                                setState(() { _loading = true; _error = null; });
                                final api = context.read<ApiService>();
                                final resp = await api.startConstruction(b.id, nextLv);
                                if (!mounted) return;
                                setState(() { _loading = false; });
                                if (resp['ok'] == true) {
                                  widget.onUpgradeOk();
                                  await context.read<ApiService>().fetchUserStats();
                                  await context.read<ApiService>().fetchBuildQueue();
                                  Navigator.pop(context);
                                } else {
                                  setState(() { _error = resp['error'] ?? 'Error desconocido'; });
                                }
                              },
                        child: _loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Text('Mejorar'),
                      ),
                    ),
                    if (b.id == 'barracks' && widget.onTrain != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onTrain!(context, b);
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
                          child: const Text('Entrenar'),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _costRow(String emoji, int v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(emoji, style: const TextStyle(color: Colors.white, fontSize: 14)), const SizedBox(width: 4), Text('$v', style: const TextStyle(color: Colors.white, fontSize: 13))],
      ),
    );

Widget _infoRow(String label, String now, String next) => Column(
      children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)), Text('$now → $next', style: const TextStyle(color: Colors.white, fontSize: 13))],
    );

String _prettyTime(int secs) {
  final m = (secs / 60).round();
  if (m < 60) return '$m min';
  final h = (m / 60).floor();
  final rm = m % 60;
  return '${h}h ${rm}m';
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

Map<String, int> _costForLevel(BuildingData d, int lv) => {
      'wood': d.baseCostWood * lv,
      'stone': d.baseCostStone * lv,
      'food': d.baseCostFood * lv,
    };
int _timeForLevel(BuildingData d, int lv) => d.baseTime * lv;
int? _production(String id, int lv) =>
    (id == 'farm' || id == 'lumbermill' || id == 'stonemine') ? lv * 50 : null;
int? _capacity(String id, int lv) => id == 'warehouse' ? lv * 500 : null;

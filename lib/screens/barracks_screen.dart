// lib/screens/barracks_screen.dart

import 'package:flutter/material.dart';
import 'package:guild_client/viewmodels/auth_viewmodels.dart';
import 'package:provider/provider.dart';
import '../models/unit.dart';
import '../services/api_service.dart';

/// Diálogo de cuartel al estilo Grepolis
Future<void> showBarracksDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const _BarracksDialog(),
  );
}

class _BarracksDialog extends StatefulWidget {
  const _BarracksDialog({Key? key}) : super(key: key);
  @override
  State<_BarracksDialog> createState() => _BarracksDialogState();
}

class _BarracksDialogState extends State<_BarracksDialog> {
  late Future<List<Unit>> _unitsFut;
  final Map<String, int> _quantities = {};
  String? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _unitsFut = context.read<ApiService>().fetchUnits();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: const Color(0xFFEEE2BA),  // fondo típico de Grepolis
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.1,
        vertical: size.height * 0.1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width * 0.8,
          maxHeight: size.height * 0.8,
        ),
        child: FutureBuilder<List<Unit>>(
          future: _unitsFut,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: \${snap.error}'));
            }
            final raceId = context.read<AuthViewModel>().raceId;
            final units = snap.data!
                .where((u) => u.requiredRace == null || u.requiredRace == raceId)
                .toList();
            if (_selectedUnitId == null && units.isNotEmpty) {
              _selectedUnitId = units.first.id;
            }
            final selected = units.firstWhere((u) => u.id == _selectedUnitId);
            final qty = _quantities[selected.id] ?? 0;
            return Column(
              children: [
                // ─── Encabezado: iconos de unidades con contador ───
                Container(
                  color: const Color(0xFFD4C49B),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: units.map((u) {
                      final count = _quantities[u.id] ?? 0;
                      final selectedBg = u.id == selected.id ? Colors.orange.withOpacity(0.3) : Colors.transparent;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedUnitId = u.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selectedBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            children: [
                              buildImage(u.id),
                              const SizedBox(height: 4),
                              Text('$count', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),
                // ─── Panel de detalle ───────────────────────────────
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8F1E0),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Imagen y selector
                        SizedBox(
                          width: size.width * 0.2,
                          child: Column(
                            children: [
                              buildImage(selected.id, size: 80),
                              const SizedBox(height: 8),
                              Text(selected.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: qty > 0 ? () => setState(() => _quantities[selected.id] = qty - 1) : null,
                                  ),
                                  Text('$qty'),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => setState(() => _quantities[selected.id] = qty + 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const VerticalDivider(),
                        // Costos y tiempo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Costos:', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Madera: \${selected.costWood * qty}'),
                              Text('Piedra: \${selected.costStone * qty}'),
                              Text('Comida: \${selected.costFood * qty}'),
                              const SizedBox(height: 12),
                              Text('Tiempo: ' + _formatTime(selected.trainTimeSecs * qty)),
                            ],
                          ),
                        ),
                        const VerticalDivider(),
                        // Stats de unidad
                        SizedBox(
                          width: size.width * 0.2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Estadísticas', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Ataque: \${selected.atk}'),
                              Text('Defensa: \${selected.def}'),
                              Text('Velocidad: \${selected.speed}'),
                              Text('Capacidad: \${selected.capacity}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ─── Cola de entrenamiento (placeholder) ─────────────
                Container(
                  height: 50,
                  color: const Color(0xFFD4C49B),
                  child: Center(child: Text('En entrenamiento (0/${selected.capacity})')),
                ),
                // ─── Acciones finales ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: qty > 0
                              ? () async {
                                  final resp = await context.read<ApiService>().startTraining(selected.id, qty);
                                  if (!mounted) return;
                                  if (resp['ok'] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Entrenamiento iniciado')),
                                    );
                                    setState(() => _quantities[selected.id] = 0);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(resp['error'] ?? 'Error')),
                                    );
                                  }
                                }
                              : null,
                          child: const Text('Entrenar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Checkbox(value: false, onChanged: null),
                          const Text('Notificaciones'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '\${m}m \${s}s';
  }
}

Widget buildImage(String id, {double size = 48}) {
  final path = 'assets/soliders/\$id.png';
  return Image.asset(
    path,
    width: size,
    height: size,
    fit: BoxFit.contain,
    color: Colors.white,
    colorBlendMode: BlendMode.srcIn,
    errorBuilder: (ctx, error, stack) => Icon(Icons.broken_image, size: size),
  );
}

// lib/screens/barracks_screen.dart

import 'package:flutter/material.dart';
import 'package:guild_client/viewmodels/auth_viewmodels.dart';
import 'package:provider/provider.dart';
import '../models/unit.dart';
import '../services/api_service.dart';

Future<void> showBarracksDialog(BuildContext context) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar cuartel',
    barrierColor: Colors.black.withOpacity(0.2),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => const _BarracksDialog(),
    transitionBuilder: (_, anim, __, child) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
  );
}

class _BarracksDialog extends StatefulWidget {
  const _BarracksDialog({Key? key}) : super(key: key);

  @override
  State<_BarracksDialog> createState() => _BarracksDialogState();
}

class _BarracksDialogState extends State<_BarracksDialog> {
  late Future<List<Unit>> _unitsFuture;
  final Map<String, int> _trainingCount = {};
  final List<Unit> _filteredUnits = [];
  int _selectedIndex = 0;
  bool _isTraining = false;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _unitsFuture = context.read<ApiService>().fetchUnits();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = screen.width * 0.85;
    final dialogHeight = screen.height * 0.75;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;
    final bg = theme.colorScheme.surface;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: bg.withOpacity(0.95),
      insetPadding: EdgeInsets.symmetric(
        horizontal: (screen.width - dialogWidth) / 2,
        vertical: (screen.height - dialogHeight) / 2,
      ),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: FutureBuilder<List<Unit>>(
          future: _unitsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Error al cargar unidades'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _unitsFuture = context.read<ApiService>().fetchUnits();
                      }),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_filteredUnits.isEmpty) {
              final raceId = context.read<AuthViewModel>().raceId;
              _filteredUnits.addAll(snapshot.data!
                  .where((u) => u.requiredRace == null || u.requiredRace == raceId)
                  .toList());
              _pageController = PageController(
                viewportFraction: 0.2,
                initialPage: _selectedIndex,
              );
            }
            if (_filteredUnits.isEmpty) {
              return const Center(
                child: Text('No hay unidades disponibles para tu raza.'),
              );
            }

            final unit = _filteredUnits[_selectedIndex];
            final count = _trainingCount[unit.id] ?? 0;
            final totalTrainingTime = unit.trainTimeSecs * count;

            return Column(
              children: [
                const SizedBox(height: 12),
                _buildTitle(accent),
                const SizedBox(height: 12),
                _buildUnitSelector(),
                const SizedBox(height: 12),
                Expanded(child: _buildImageAndStats(unit)),
                const SizedBox(height: 12),
                _buildFooter(unit, count, totalTrainingTime, accent),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitle(Color accent) {
    return Text(
      'Entrenar unidades',
      style: TextStyle(
        color: accent,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildUnitSelector() {
    return SizedBox(
      height: 72,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _filteredUnits.length,
        onPageChanged: (i) => setState(() => _selectedIndex = i),
        itemBuilder: (_, i) {
          final u = _filteredUnits[i];
          final isSelected = i == _selectedIndex;
          return Center(
            child: GestureDetector(
              onTap: () => _pageController?.animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: buildImage(u.id, size: 32)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageAndStats(Unit unit) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Row(
        key: ValueKey(unit.id),
        children: [
          Flexible(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(right: 12),
              child: Center(child: buildImage(unit.id, size: 64)),
            ),
          ),
          Flexible(
            flex: 7,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(unit.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 20,
                    children: [
                      _statText('Atk', unit.atk),
                      _statText('Def', unit.def),
                      _statText('Vel', unit.speed),
                      _statText('Cap', unit.capacity),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Unit unit, int count, int totalTime, Color accent) {
    final authVm = context.read<AuthViewModel>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                color: accent,
                onPressed: count > 0 ? () => setState(() => _trainingCount[unit.id] = count - 1) : null,
              ),
              Text('$count', style: const TextStyle(fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add),
                color: accent,
                onPressed: () => setState(() => _trainingCount[unit.id] = count + 1),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('🪵${unit.costWood * count} 🪨${unit.costStone * count} 🍖${unit.costFood * count}'),
              const SizedBox(height: 4),
              Text('⏱️ ${_formatDuration(totalTime)}'),
            ],
          ),
          const SizedBox(width: 12),
          ElevatedButton(
  onPressed: (count > 0 && !_isTraining)
      ? () async {
          setState(() => _isTraining = true);
          try {
            final resp = await context.read<ApiService>().startTraining(
              unitType: unit.id,
              quantity: count,
            );
            if (!mounted) return;
            if (resp['ok'] == true || resp['status'] == 'queued') {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Entrenamiento iniciado')));
              setState(() => _trainingCount[unit.id] = 0);
            } else {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(resp['error'] ?? 'Error desconocido')));
            }
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Error de conexión')));
          } finally {
            if (mounted) setState(() => _isTraining = false);
          }
        }
      : null,
  style: ElevatedButton.styleFrom(backgroundColor: accent),
  child: _isTraining
      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
      : const Text('Entrenar'),
),
        ],
      ),
    );
  }

  Widget _statText(String label, int val) => Text('$label: $val');

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }
}

Widget buildImage(String id, {double size = 48}) {
  final path = 'assets/soliders/$id.png';
  return Image.asset(
    path,
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (ctx, _, __) => Icon(Icons.broken_image, size: size),
  );
}

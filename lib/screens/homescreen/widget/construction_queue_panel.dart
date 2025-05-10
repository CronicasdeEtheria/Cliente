// lib/widgets/construction_queue_panel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guild_client/services/api_service.dart';
import 'package:provider/provider.dart';

class ConstructionQueuePanel extends StatefulWidget {
  const ConstructionQueuePanel({Key? key}) : super(key: key);

  @override
  State<ConstructionQueuePanel> createState() => _ConstructionQueuePanelState();
}

class _ConstructionQueuePanelState extends State<ConstructionQueuePanel> {
  Timer? _tickTimer;
  Timer? _refreshTimer;
  Map<String, dynamic>? _data;
  bool _loading = false;

  static const int _maxConcurrent = 3; // Ajusta según tu configuración de servidor

  @override
  void initState() {
    super.initState();
    _fetchQueue();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchQueue());
  }

  Future<void> _fetchQueue() async {
    setState(() => _loading = true);
    try {
      final result = await context.read<ApiService>().fetchBuildQueue();
      setState(() => _data = result);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _updateRemaining() {
    if (_data == null) return;
    final raw = (_data!['queue'] as List<dynamic>? ?? []);
    final updated = raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final int rem = m['remaining'] is int
          ? m['remaining'] as int
          : int.tryParse('${m['remaining']}') ?? 0;
      m['remaining'] = rem > 0 ? rem - 1 : 0;
      return m;
    }).where((m) => (m['remaining'] as int) > 0).toList();
    setState(() => _data!['queue'] = updated);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queue = (_data?['queue'] as List<dynamic>?) ?? [];
    final max = _data?['max'] as int? ?? _maxConcurrent;

    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 60),
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.35),
          borderRadius: BorderRadius.circular(6),
        ),
        child: _loading
            ? const SizedBox(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cola ${queue.length}/$max',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const Divider(color: Colors.white24, height: 8),
                  ...queue.take(max).map((e) => _buildItem(e as Map<String, dynamic>)),
                  if (queue.length > max)
                    Text(
                      '+${queue.length - max} más',
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  if (queue.isEmpty)
                    const Text(
                      'Sin construcciones',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> e) {
    final String? id = e['id'] as String?;
    final building = e['building'] as String? ?? '';
    final target = e['target'] as int? ?? 0;
    final sec = e['remaining'] as int? ?? 0;
    final min = sec ~/ 60;
    final s = sec % 60;
    final time = '${min.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_nice[building] ?? building}→Lv$target',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: Colors.orange, fontSize: 10),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            iconSize: 14,
            color: Colors.redAccent,
            icon: const Icon(Icons.close),
            onPressed: (!_loading && id != null)
                ? () async {
                    setState(() => _loading = true);
                    await context.read<ApiService>().cancelConstruction(id);
                    await _fetchQueue();
                    setState(() => _loading = false);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  static const _nice = {
    'townhall': 'Ayto.',
    'farm': 'Granja',
    'lumbermill': 'Aserradero',
    'stonemine': 'Mina',
    'warehouse': 'Almacén',
    'barracks': 'Cuartel',
    'coliseo': 'Coliseo',
  };
}

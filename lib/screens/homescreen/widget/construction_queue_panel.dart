// lib/widgets/construction_queue_panel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guild_client/services/api_service.dart';
import 'package:provider/provider.dart';

class ConstructionQueuePanel extends StatefulWidget {
  const ConstructionQueuePanel({super.key});

  @override
  State<ConstructionQueuePanel> createState() => _ConstructionQueuePanelState();
}

class _ConstructionQueuePanelState extends State<ConstructionQueuePanel> {
  late Timer _timer;
  Map<String, dynamic>? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchQueue();
    // Actualiza cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _fetchQueue() async {
    final result = await context.read<ApiService>().fetchBuildQueue();
    setState(() => _data = result);
  }

  void _tick() {
    if (_data == null) return;
    final rawQueue = (_data!['queue'] as List<dynamic>? ?? []);
    final updated = rawQueue.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      m['remaining'] = (m['remaining'] as int) - 1;
      return m;
    }).where((e) => (e['remaining'] as int) > 0).toList();
    setState(() {
      _data!['queue'] = updated;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Panel flotante pequeño en esquina
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
        child: _data == null
            ? const SizedBox(
                height: 40,
                child: Center(
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final queue = (_data!['queue'] as List<dynamic>?) ?? [];
    final max = _data!['max'] as int? ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Título compacto
        Text(
          'Cola ${queue.length}/$max',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const Divider(color: Colors.white24, height: 8),
        // Items
        ...queue.take(3).map((e) => _buildItem(e as Map<String, dynamic>)),
        if (queue.length > 3)
          Text(
            '+${queue.length - 3} más',
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        if (queue.isEmpty)
          const Text(
            'Sin construcciones',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
      ],
    );
  }

  Widget _buildItem(Map<String, dynamic> e) {
    final sec = e['remaining'] as int;
    final min = sec ~/ 60;
    final s = sec % 60;
    final time = '${min.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_nice[e['building']] ?? e['building']}→Lv${e['target']}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: Colors.orange, fontSize: 10),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 18,
            height: 18,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 14,
              color: Colors.redAccent,
              icon: const Icon(Icons.close),
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      await context.read<ApiService>().cancelConstruction();
                      await _fetchQueue();
                      setState(() => _loading = false);
                    },
            ),
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

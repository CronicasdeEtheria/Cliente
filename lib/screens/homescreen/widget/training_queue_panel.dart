// lib/widgets/training_queue_panel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guild_client/services/api_service.dart';
import 'package:provider/provider.dart';

class TrainingQueuePanel extends StatefulWidget {
  const TrainingQueuePanel({Key? key}) : super(key: key);

  @override
  State<TrainingQueuePanel> createState() => _TrainingQueuePanelState();
}

class _TrainingQueuePanelState extends State<TrainingQueuePanel> {
  Timer? _tickTimer;
  Timer? _refreshTimer;

  String _status = 'idle';
  String _unitType = '';
  int _quantity = 0;
  int _remaining = 0;
  bool _loading = false;

  static const int _maxConcurrent = 2;

  @override
  void initState() {
    super.initState();
    _fetchQueueStatus();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _decrementTick());
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchQueueStatus());
  }

  Future<void> _fetchQueueStatus() async {
    setState(() => _loading = true);
    try {
      final result = await context.read<ApiService>().fetchQueueStatus();
      final training = result['training'] as Map<String, dynamic>;
      setState(() {
        _status = training['status'] as String;
        if (_status == 'training') {
          _unitType = training['unit_type'] as String;
          _quantity = training['quantity'] as int;
          _remaining = training['remaining_seconds'] as int;
        }
      });
    } catch (_) {
      // Ignorar errores
    } finally {
      setState(() => _loading = false);
    }
  }

  void _decrementTick() {
    if (_status == 'training' && _remaining > 0) {
      setState(() {
        _remaining--;
        if (_remaining <= 0) _status = 'completed';
      });
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = (_status == 'training') ? 1 : 0;

    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 180),
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
                    'Cuartel ($current/$_maxConcurrent)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 8),
                  _buildContent(),
                ],
              ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case 'training':
        final min = _remaining ~/ 60;
        final s = _remaining % 60;
        final time = '${min.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrenando', style: TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              '${_nice[_unitType] ?? _unitType} x$_quantity',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
            Text(time, style: const TextStyle(color: Colors.orange, fontSize: 10)),
          ],
        );
      case 'completed':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrenamiento completado', style: TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              '${_nice[_unitType] ?? _unitType} x$_quantity',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            const Icon(Icons.check, color: Colors.green, size: 14),
          ],
        );
      default:
        return const Text(
          'Sin entrenamiento',
          style: TextStyle(color: Colors.white38, fontSize: 10),
        );
    }
  }

  static const _nice = {
    'archer': 'Arqueros',
    'swordsman': 'Espadachines',
  };
}

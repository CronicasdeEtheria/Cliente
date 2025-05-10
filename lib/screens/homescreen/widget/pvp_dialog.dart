import 'package:flutter/material.dart';
import 'package:guild_client/services/api_service.dart';
import 'package:guild_client/models/unit.dart';
import 'package:provider/provider.dart';

Future<void> showPvPDialog(BuildContext context) async {
  final size = MediaQuery.of(context).size;
  final dialogWidth = size.width * 0.8;
  final dialogHeight = size.height * 0.7;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Center(
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: const _PvPDialog(),
      ),
    ),
  );
}

class _PvPDialog extends StatefulWidget {
  const _PvPDialog({Key? key}) : super(key: key);
  @override
  State<_PvPDialog> createState() => _PvPDialogState();
}

class _PvPDialogState extends State<_PvPDialog> {
  Map<String, int> _available = {};
  List<Unit> _catalog = [];
  final Map<String, TextEditingController> _ctrls = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = context.read<ApiService>();
    final rawArmy = await api.fetchUserArmy();
    final rawUnits = await api.fetchUnits();
    final avail = <String,int>{};
    for (var e in rawArmy) {
      avail[e['unit_type'] as String] = e['quantity'] as int;
    }
    setState(() { _available = avail; _catalog = rawUnits; });
    for (var type in avail.keys) {
      _ctrls[type] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (var c in _ctrls.values) c.dispose();
    super.dispose();
  }

  void _search() {
    final send = <String,int>{};
    for (var entry in _ctrls.entries) {
      final v = int.tryParse(entry.value.text) ?? 0;
      if (v > 0) send[entry.key] = v;
    }
    if (send.isEmpty) {
      setState(() => _error = 'Selecciona al menos una unidad');
      return;
    }
    context.read<ApiService>().randomBattleWithArmy(send);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tus unidades están en busca de algun oponente'))
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tus unidades', style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 12),
            for (var entry in _available.entries.where((e) => e.value > 0)) ...[
  _unitRow(entry.key),
  const SizedBox(height: 8),
],
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: _search,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Buscar oponente'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _unitRow(String type) {
    final unit = _catalog.firstWhere((u) => u.id == type);
    final avail = _available[type] ?? 0;
    return Row(
      children: [
        Image.asset(
          'assets/soliders/${unit.id}.png',
          width: 40,
          height: 40,
          errorBuilder: (_,__,___) => const Icon(Icons.image, color: Colors.white54),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${unit.name} (x$avail)', style: const TextStyle(color: Colors.white)),
              Text('Atk ${unit.atk} Def ${unit.def} HP ${unit.hp}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          child: TextField(
            controller: _ctrls[type],
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              counterText: '',
              fillColor: Colors.grey[800],
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
      ],
    );
  }
}

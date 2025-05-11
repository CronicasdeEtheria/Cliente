import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../viewmodels/auth_viewmodels.dart';

Future<void> showReportsDialog(BuildContext context) async {
  final size = MediaQuery.of(context).size;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        width: size.width * 0.7,
        height: size.height * 0.75,
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: const _ReportsView(),
      ),
    ),
  );
}

class _ReportsView extends StatefulWidget {
  const _ReportsView({Key? key}) : super(key: key);
  @override
  _ReportsViewState createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  late Future<List<dynamic>> _reports;

  @override
  void initState() {
    super.initState();
    _reports = context.read<ApiService>().fetchBattleReports();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthViewModel>().username;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1F1F1F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timeline, color: Colors.orange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Informes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _reports,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                );
              }
              final list = snap.data;
              if (snap.hasError || list == null || list.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay informes',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }
              final count = list.length > 3 ? 3 : list.length;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: count,
                itemBuilder: (_, i) {
                  final r = list[i] as Map<String, dynamic>;
final opponent = r['opponent'] as String? ?? '';
final isAtt = r['as'] == 'attacker';
final att = isAtt ? me : opponent;
final def = isAtt ? opponent : me;
final date = _format(r['date'] as String? ?? '');
final winRole = r['winner'] as String? ?? '';
final winnerName = winRole == 'attacker' ? att : def;
final elo = r['elo_delta'] as int? ?? 0;
final gold = r['gold_reward'] as int? ?? 0;
final used = Map<String, dynamic>.from(r['army_used'] as Map);
final lost = Map<String, dynamic>.from(r['army_lost'] as Map);

                  return Card(
                    color: const Color(0xFF333333),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
Row(
  children: [
    Text(att, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    if (winRole == 'attacker') ...[
      const SizedBox(width: 4),
      const Icon(Icons.emoji_events, color: Colors.yellowAccent, size: 16),
    ],
    const SizedBox(width: 4),
    const Text('⚔️', style: TextStyle(fontSize: 16)),
    const SizedBox(width: 4),
    Text(def, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    if (winRole == 'defender') ...[
      const SizedBox(width: 4),
      const Icon(Icons.emoji_events, color: Colors.yellowAccent, size: 16),
    ],
  ],
),
const SizedBox(height: 4),
                          Text(
                            date,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          // Stats row
                          Row(
                            children: [
                              _Stat(label: winnerName, icon: Icons.emoji_events),
                              const SizedBox(width: 12),
                              _Stat(label: '${elo > 0 ? '+' : ''}$elo', icon: Icons.star),
                              const SizedBox(width: 12),
                              _Stat(label: '$gold', icon: Icons.monetization_on),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Units
                          SizedBox(
                            height: 72,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: used.entries.map((e) {
                                final type = e.key;
                                final sent = e.value as int;
                                final loss = lost[type] as int? ?? 0;
                                final surv = sent - loss;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.grey[700],
                                        backgroundImage:
                                            AssetImage('assets/soliders/$type.png'),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'S:$surv',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Footer
        if ((context.read<ApiService>().fetchBattleReports().toString()) != '')
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              listIsLong ? 's' : '',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
      ],
    );
  }

  bool get listIsLong => true; // always show footer if more exist

  static String _format(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Stat({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2F2F2F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

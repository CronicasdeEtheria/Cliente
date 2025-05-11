import 'package:flutter/material.dart';
import 'package:guild_client/models/race.dart';
import 'package:guild_client/services/api_service.dart';

const Color _accentColor = Color(0xFFFF8800);

/// Modelo para una entrada de ranking con raza
class RankingEntry {
  final String username;
  final int value;
  final String raceId;

  RankingEntry({
    required this.username,
    required this.value,
    required this.raceId,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json, String type) {
    final key = (type == 'elo')
        ? 'elo'
        : (type == 'production')
            ? 'produced_total'
            : 'wins';
    return RankingEntry(
      username: json['username'] as String,
      value: json[key] is int
          ? json[key] as int
          : int.parse(json[key].toString()),
      raceId: json['race'] as String? ?? 'unknown',
    );
  }
}

/// Diálogo de ranking con filtros y orden dinámico
Future<void> showRankingDialog(BuildContext context, {String type = 'elo'}) async {
  final api = ApiService();
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black38,
    builder: (_) => RankingDialog(api: api, type: type),
  );
}

class RankingDialog extends StatefulWidget {
  final ApiService api;
  final String type;
  const RankingDialog({Key? key, required this.api, this.type = 'elo'}) : super(key: key);

  @override
  _RankingDialogState createState() => _RankingDialogState();
}

class _RankingDialogState extends State<RankingDialog> {
  List<RankingEntry> _all = [];
  List<RankingEntry> _filtered = [];
  List<Race> _races = [];
  bool _loading = true;
  String _query = '';
  String? _selectedRaceId;
  bool _sortByName = true;
  bool _ascending = true;

  String get _title {
    switch (widget.type) {
      case 'production': return 'Ranking Producción';
      case 'victories': return 'Ranking Victorias';
      default: return 'Ranking';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final raw = await widget.api.fetchUserRanking(
        type: widget.type,
        race: _selectedRaceId,
        limit: 30,
      );
      final list = (raw as List<dynamic>)
          .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>, widget.type))
          .toList();
      final racesRaw = await widget.api.fetchRaces();
      setState(() {
        _all = list;
        _filtered = list;
        _races = racesRaw;
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    var list = _all;
    if (_query.isNotEmpty) {
      list = list.where((e) => e.username.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    list.sort((a, b) {
      int cmp = _sortByName ? a.username.compareTo(b.username) : a.value.compareTo(b.value);
      return _ascending ? cmp : -cmp;
    });
    setState(() => _filtered = list);
  }

  void _onRaceTap(String? raceId) {
    setState(() {
      _selectedRaceId = raceId == _selectedRaceId ? null : raceId;
      _loading = true;
    });
    _loadData();
  }

  void _toggleSortBy(bool byName) {
    setState(() {
      if (_sortByName == byName) _ascending = !_ascending;
      else { _sortByName = byName; _ascending = true; }
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.6;
    final height = MediaQuery.of(context).size.height * 0.9;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Search field much narrower and shorter
            SizedBox(
              width: width * 0.25,
              height: 28,
              child: TextField(
                onChanged: (q) { _query = q; _applyFilters(); },
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 16),
                  filled: true,
                  fillColor: Colors.white12,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Race filters
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: () => _onRaceTap(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      child: Text(
                        'Todas',
                        style: TextStyle(
                          color: _selectedRaceId == null ? _accentColor : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  ..._races.map((r) {
                    final selected = r.id == _selectedRaceId;
                    return GestureDetector(
                      onTap: () => _onRaceTap(r.id),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          border: Border.all(color: selected ? _accentColor : Colors.white10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Image.asset(
                          r.assetPath,
                          width: 24,
                          height: 24,
                          errorBuilder: (_, __, ___) => const Text('e', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Column headers for sorting
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleSortBy(true),
                    child: Row(
                      children: [
                        Text('Nombre', style: TextStyle(color: _sortByName ? _accentColor : Colors.white70, fontSize: 12)),
                        const SizedBox(width: 4),
                        if (_sortByName)
                          Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: _accentColor),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleSortBy(false),
                  child: Row(
                    children: [
                      Text('Elo', style: TextStyle(color: !_sortByName ? _accentColor : Colors.white70, fontSize: 12)),
                      const SizedBox(width: 4),
                      if (!_sortByName)
                        Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: _accentColor),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 8),
            // List of entries
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: _accentColor))
                  : _filtered.isEmpty
                      ? const Center(child: Text('Sin resultados', style: TextStyle(color: Colors.white54, fontSize: 12)))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemExtent: 32, // fixed small height for more items
                          itemBuilder: (context, i) {
                            final e = _filtered[i];
                            final raceObj = _races.firstWhere(
                              (r) => r.id == e.raceId,
                              orElse: () => Race(id: 'unknown', displayName: 'Desconocido', emoji: ''),
                            );
                            return Row(
                              children: [
                                Image.asset(
                                  raceObj.assetPath,
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (_, __, ___) => const Text('e', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${i + 1}. ${e.username}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${e.value}',
                                  style: const TextStyle(color: _accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            );
                          },
                        ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

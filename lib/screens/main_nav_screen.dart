import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:guild_client/screens/homescreen/widget/informes_dialog.dart';
import 'package:guild_client/screens/homescreen/widget/ranking_dialog.dart';
import 'homescreen/home_screen.dart';
import 'homescreen/guild/guild_list_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({Key? key}) : super(key: key);
  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  bool _open = false;
  int _unreadReports = 0;
  late final AnimationController _ctrl;
  late final Animation<double> _heightAnim;
  final accent = const Color(0xFFFF8800);

  static const _pages = [
    HomeScreen(),
    Center(child: Text('Mapa - próximamente', style: TextStyle(color: Colors.white70, fontSize: 16)))
  ];

  // Dimensiones reducidas
  static const double _toggleSize = 56;
  static const double _cellHeight = 56;
  static const int _itemCount = 5;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    // Altura animada: toggle + celdas cuando expande
    _heightAnim = Tween<double>(
      begin: _toggleSize,
      end: _toggleSize + _cellHeight * _itemCount,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) _ctrl.forward(); else _ctrl.reverse();
  }

  void _onNavTap(int index) {
    _toggle();
    switch (index) {
      case 0:
        setState(() => _current = 0);
        break;
      case 1:
        showGuildDialog(context);
        break;
      case 2:
        setState(() => _current = 1);
        break;
      case 3:
        showReportsDialog(context);
        break;
      case 4:
        showRankingDialog(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          _pages[_current],
          Positioned(
            left: 20,
            bottom: safe + 20,
            child: AnimatedBuilder(
              animation: _heightAnim,
              builder: (_, __) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      width: _toggleSize,
                      height: _heightAnim.value,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_open) ...[
                            _NavCell(
                              label: 'Ranking',
                              icon: Icons.leaderboard,
                              badgeCount: 0,
                              selected: false,
                              accent: accent,
                              onTap: () => _onNavTap(4),
                            ),
                            _NavCell(
                              label: 'Informes',
                              icon: Icons.list_alt,
                              badgeCount: _unreadReports,
                              selected: false,
                              accent: accent,
                              onTap: () => _onNavTap(3),
                            ),
                            _NavCell(
                              label: 'Mapa',
                              icon: Icons.map,
                              badgeCount: 0,
                              selected: _current == 1,
                              accent: accent,
                              onTap: () => _onNavTap(2),
                            ),
                            _NavCell(
                              label: 'Gremio',
                              icon: Icons.shield_moon,
                              badgeCount: 0,
                              selected: false,
                              accent: accent,
                              onTap: () => _onNavTap(1),
                            ),
                            _NavCell(
                              label: 'Aldea',
                              icon: Icons.villa,
                              badgeCount: 0,
                              selected: _current == 0,
                              accent: accent,
                              onTap: () => _onNavTap(0),
                            ),
                          ],
                          _ToggleButton(
                            accent: accent,
                            open: _open,
                            onTap: _toggle,
                            badgeCount: _unreadReports,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

class _ToggleButton extends StatelessWidget {
  final Color accent;
  final bool open;
  final VoidCallback onTap;
  final int badgeCount;
  const _ToggleButton({
    required this.accent,
    required this.open,
    required this.onTap,
    this.badgeCount = 0,
  });
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            width: _MainNavScreenState._toggleSize,
            height: _MainNavScreenState._toggleSize,
            alignment: Alignment.center,
            child: Icon(
              open ? Icons.close : Icons.menu,
              color: accent,
              size: 24,
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _NavCell extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final int badgeCount;
  const _NavCell({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.badgeCount = 0,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _MainNavScreenState._toggleSize,
      height: _MainNavScreenState._cellHeight,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? accent : Colors.white54),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 8, color: selected ? accent : Colors.white60),
            ),
            if (badgeCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 6),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

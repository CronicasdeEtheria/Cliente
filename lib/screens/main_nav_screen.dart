import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:guild_client/screens/homescreen/widget/informes_dialog.dart';
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
  late AnimationController _ctrl;
  final accent = const Color(0xffff8800);

  static const _pages = [
    HomeScreen(),
    Center(child: Text('Mapa - próximamente', style: TextStyle(color: Colors.white70, fontSize: 16)))
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) _ctrl.forward(); else _ctrl.reverse();
  }

  void _onNavTap(int index) {
    _toggle();
    if (index == 0) setState(() => _current = 0);
    if (index == 1) showGuildDialog(context);
    if (index == 2) setState(() => _current = 1);
    if (index == 3) showReportsDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding.bottom;
    const cellW = 70.0;
    const collapsedW = 56.0;
    const expandedCount = 4;
    final expandedW = collapsedW + cellW * expandedCount;

    return Scaffold(
      body: Stack(
        children: [
          _pages[_current],
          Positioned(
            left: 20,
            bottom: safe + 20,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final w = collapsedW + (expandedW - collapsedW) * _ctrl.value;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      width: w,
                      height: 56,
                      decoration: BoxDecoration(color: Colors.black.withOpacity(.8), borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          _ToggleButton(accent: accent, open: _open, onTap: _toggle, badgeCount: _unreadReports),
                          if (_open) ...[
                            _NavCell(label: 'Aldea', icon: Icons.villa, selected: _current == 0, accent: accent, onTap: () => _onNavTap(0)),
                            _NavCell(label: 'Gremio', icon: Icons.shield_moon, selected: false, accent: accent, onTap: () => _onNavTap(1)),
                            _NavCell(label: 'Mapa', icon: Icons.map, selected: _current == 1, accent: accent, onTap: () => _onNavTap(2)),
                            _NavCell(label: 'Informes', icon: Icons.list_alt, selected: false, accent: accent, onTap: () => _onNavTap(3), badgeCount: _unreadReports),
                          ],
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
  const _ToggleButton({required this.accent, required this.open, required this.onTap, this.badgeCount = 0});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(width: 56, height: 56, alignment: Alignment.center, child: Icon(open ? Icons.close : Icons.menu, color: accent, size: 28)),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
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
  const _NavCell({required this.label, required this.icon, required this.selected, required this.accent, required this.onTap, this.badgeCount = 0});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: selected ? accent : Colors.white60)),
            const SizedBox(height: 4),
            Stack(
              children: [
                Icon(icon, size: 24, color: selected ? accent : Colors.white54),
                if (badgeCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// lib/screens/main_nav_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'homescreen/home_screen.dart';
import 'chat_screen.dart';
import 'guild_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});
  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with SingleTickerProviderStateMixin {
  int  _current = 0;
  bool _open    = false;
  late AnimationController _ctrl;
  final accent = const Color(0xffff8800);

  static const _pages = [HomeScreen(), ChatScreen(), GuildScreen()];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding.bottom;
    const cellW = 70.0;                    // ancho de cada celda
    const collapsedW = 56.0;               // sólo el escudo
    const expandedCount = 3;               // ajusta si agregas más
    final expandedW = collapsedW + cellW * expandedCount;

    return Scaffold(
      body: Stack(
        children: [
          _pages[_current],

          // ----------------- Dock desplegable -----------------
          Positioned(
            left: 20,
            bottom: safe + 20,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final w =
                    collapsedW + (expandedW - collapsedW) * _ctrl.value;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      width: w,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          // botón escudo (abre/cierra)
                          _ToggleButton(accent: accent, open: _open, onTap: _toggle),

                          // opciones – se muestran cuando _open
                          if (_open) ...[
                            _NavCell(
                              label: 'Mapa',
                              icon: Icons.map_rounded,
                              selected: _current == 0,
                              accent: accent,
                              onTap: () {
                                setState(() => _current = 0);
                                _toggle();
                              },
                            ),
                            _NavCell(
                              label: 'Chat',
                              icon: Icons.forum_rounded,
                              selected: _current == 1,
                              accent: accent,
                              onTap: () {
                                setState(() => _current = 1);
                                _toggle();
                              },
                            ),
                            _NavCell(
                              label: 'Gremio',
                              icon: Icons.shield_moon,
                              selected: _current == 2,
                              accent: accent,
                              onTap: () {
                                setState(() => _current = 2);
                                _toggle();
                              },
                            ),
                            // Agrega más _NavCell si lo necesitas
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

// ═════════════════════ Widgets auxiliares ═══════════════════════════

// Botón escudo abre/cierra el dock
class _ToggleButton extends StatelessWidget {
  final Color accent;
  final bool open;
  final VoidCallback onTap;
  const _ToggleButton({
    required this.accent,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        child: Icon(
          open ? Icons.close : Icons.shield, // escudo al estar cerrado
          color: accent,
          size: 28,
        ),
      ),
    );
  }
}

// Celda con icono + texto encima
class _NavCell extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _NavCell({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? accent : Colors.white60)),
            const SizedBox(height: 4),
            Icon(icon, size: 24, color: selected ? accent : Colors.white54),
          ],
        ),
      ),
    );
  }
}

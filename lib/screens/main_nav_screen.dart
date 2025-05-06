// lib/screens/main_nav_screen.dart
//
// • Barra flotante de 44 px con blur y sombra.
// • Sin padding extra: el contenido se ve “por detrás” de la barra.
// • Toda la celda es táctil (Expanded + InkWell), no solo el icono.

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

class _MainNavScreenState extends State<MainNavScreen> {
  int _current = 0;
  final accent = const Color(0xffff8800);

  static const _pages = [HomeScreen(), ChatScreen(), GuildScreen()];

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding.bottom;   // zona de gestos

    return Scaffold(
      body: Stack(
        children: [
          // ------------ contenido; SIN padding ------------
          _pages[_current],

          // ---------------- barra flotante ----------------
          Positioned(
            left: 32,
            right: 32,
            bottom: safe + 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xff1b1b1b).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _NavCell(
                        index: 0,
                        current: _current,
                        icon: Icons.map_rounded,
                        accent: accent,
                        onTap: () => setState(() => _current = 0),
                      ),
                      _NavCell(
                        index: 1,
                        current: _current,
                        icon: Icons.forum_rounded,
                        accent: accent,
                        onTap: () => setState(() => _current = 1),
                      ),
                      _NavCell(
                        index: 2,
                        current: _current,
                        icon: Icons.shield_moon,
                        accent: accent,
                        onTap: () => setState(() => _current = 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Celda táctil completa
class _NavCell extends StatelessWidget {
  final int index;
  final int current;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _NavCell({
    required this.index,
    required this.current,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withOpacity(.2),
        highlightColor: Colors.transparent,
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: selected ? accent : Colors.white54,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:guild_client/screens/homescreen/home_screen.dart';

import 'chat_screen.dart';
import 'guild_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;
  final tabs = [
    const HomeScreen(),
    const ChatScreen(),
    const GuildScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.chat),      label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.group),     label: 'Gremios'),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

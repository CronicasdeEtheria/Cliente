// lib/widgets/global_chat_panel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guild_client/viewmodels/auth_viewmodels.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/api_service.dart';

/// Panel de chat global con auto-ocultamiento y animación.
class GlobalChatPanel extends StatefulWidget {
  const GlobalChatPanel({Key? key}) : super(key: key);

  @override
  State<GlobalChatPanel> createState() => _GlobalChatPanelState();
}

class _GlobalChatPanelState extends State<GlobalChatPanel> {
  late Timer _refreshTimer;
  Timer? _hideTimer;
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  bool _visible = true;
  final int _maxMessages = 20;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchMessages());
    _startHideCountdown();
  }

  void _startHideCountdown() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      setState(() => _visible = false);
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final api = context.read<ApiService>();
      final list = await api.fetchChatHistory();
      setState(() {
        _messages
          ..clear()
          ..addAll(list.take(_maxMessages));
      });
    } catch (_) {
      // Ignorar errores de red
    }
  }

  Future<void> _sendMessage() async {
    _startHideCountdown();
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      await api.sendGlobalMessage(text);
      _controller.clear();
      await _fetchMessages();
      setState(() => _visible = true);
    } catch (_) {
      setState(() => _visible = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final width = MediaQuery.of(context).size.width * 0.4;
    const height = 150.0;
    const collapsedHeight = 32.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 8),
        width: width,
        height: _visible ? height : collapsedHeight,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Header siempre visible con tap para alternar
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _visible = !_visible);
                if (_visible) _startHideCountdown();
              },
              child: Container(
                height: collapsedHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    const Text('Chat Global', style: TextStyle(color: Colors.white, fontSize: 12)),
                    const Spacer(),
                    Icon(
                      _visible ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            // Contenido: solo si visible
            if (_visible) ...[
              Expanded(child: _buildMessageList(auth.username)),
              const Divider(color: Colors.white24, height: 1),
              _buildInputRow(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(String currentUser) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(8),
      itemCount: _messages.length,
      itemBuilder: (_, idx) {
        final msg = _messages[_messages.length - 1 - idx];
        final isMe = msg.user == currentUser;
        return _buildBubble(msg, isMe);
      },
    );
  }

  Widget _buildBubble(Message msg, bool isMe) {
    final time = msg.time;
    final timestamp =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final bgColor = isMe ? Colors.orange : Colors.grey[800];
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final cross = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: cross,
          children: [
            Text(msg.user, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            const SizedBox(height: 4),
            Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(height: 2),
            Text(timestamp, style: const TextStyle(color: Colors.white54, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_loading,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Escribe...',
                hintStyle: TextStyle(color: Colors.white54),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.orange),
            onPressed: _loading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

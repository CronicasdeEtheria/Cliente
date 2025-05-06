import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/message.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    return FutureBuilder<List<Message>>(
      future: api.fetchChatHistory(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final msgs = snap.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final m = msgs[i];
            return ListTile(
              title: Text(m.user),
              subtitle: Text(m.text),
              trailing: Text(
                '${m.time.hour.toString().padLeft(2,'0')}:${m.time.minute.toString().padLeft(2,'0')}',
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        );
      },
    );
  }
}

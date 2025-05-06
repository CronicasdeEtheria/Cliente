import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/guild.dart';

class GuildScreen extends StatelessWidget {
  const GuildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    return FutureBuilder<List<Guild>>(
      future: api.fetchGuilds(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final guilds = snap.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: guilds.length,
          separatorBuilder: (_,__) => const Divider(),
          itemBuilder: (_, i) {
            final g = guilds[i];
            return ListTile(
              leading: const Icon(Icons.shield),
              title: Text(g.name),
              subtitle: Text('Miembros: ${g.members}'),
            );
          },
        );
      },
    );
  }
}

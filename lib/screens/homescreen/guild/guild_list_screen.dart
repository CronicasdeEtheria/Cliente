// lib/screens/guild_screen.dart

import 'package:flutter/material.dart';
import 'package:guild_client/screens/homescreen/guild/create_guild_screen.dart';
import 'package:guild_client/screens/homescreen/guild/myguid_view_screen.dart';
import 'package:guild_client/viewmodels/auth_viewmodels.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../models/guild.dart';

/// Muestra el diálogo de Gremio sobre el HomeScreen.
Future<void> showGuildDialog(BuildContext context) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar gremio',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => const _GuildDialog(),
    transitionBuilder: (_, anim, __, child) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
  );
}

class _GuildDialog extends StatefulWidget {
  const _GuildDialog({Key? key}) : super(key: key);
  @override
  State<_GuildDialog> createState() => _GuildDialogState();
}

class _GuildDialogState extends State<_GuildDialog> {
  late Future<Map<String, dynamic>> _profileFut;

  @override
  void initState() {
    super.initState();
    _profileFut = context.read<ApiService>().getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final width = screen.width * 0.85;
    final height = screen.height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.grey[900]?.withOpacity(0.95),
      insetPadding: EdgeInsets.symmetric(
        horizontal: (screen.width - width) / 2,
        vertical: (screen.height - height) / 2,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileFut,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.orange));
            }
            if (snap.hasError) {
              return Center(
                  child: Text('Error: ${snap.error}',
                      style: const TextStyle(color: Colors.redAccent)));
            }
            final profile = snap.data!;
            final guildId = (profile['guildId'] ?? profile['guild_id']) as String?;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: guildId == null || guildId.isEmpty
                  ? _GuildListView(api: context.read<ApiService>())
                  : MyGuildView(
                      api: context.read<ApiService>(),
                      guildId: guildId,
                      currentUser:
                          context.read<AuthViewModel>().username,
                    ),
            );
          },
        ),
      ),
    );
  }
}

/// Lista de gremios con buscador, vista en carrusel y FAB para crear.
class _GuildListView extends StatefulWidget {
  final ApiService api;
  const _GuildListView({required this.api});

  @override
  State<_GuildListView> createState() => _GuildListViewState();
}

class _GuildListViewState extends State<_GuildListView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _search = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Guild>>(
      future: widget.api.fetchGuilds(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.orange));
        }
        if (snap.hasError) {
          return Center(
            child: Text('Error: ${snap.error}',
                style: const TextStyle(color: Colors.redAccent)),
          );
        }
        final allGuilds = snap.data!;
        final filtered = _search.isEmpty
            ? allGuilds
            : allGuilds
                .where((g) =>
                    g.name.toLowerCase().contains(_search.toLowerCase()))
                .toList();

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '🔍 Buscar gremio...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      return _buildGuildCard(filtered[i], i, filtered.length);
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: Colors.orange,
                onPressed: () => showCreateGuildDialog(context),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuildCard(Guild g, int index, int total) {
    return Container(
      width: 260,
      margin: EdgeInsets.only(
        left: index == 0 ? 16 : 8,
        right: index == total - 1 ? 16 : 8,
      ),
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                    '${widget.api.baseUrl}/guild/image/${g.id}'),
                backgroundColor: Colors.grey[800],
              ),
              const SizedBox(height: 12),
              Text(
                '🏷️ ${g.name}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '👥 ${g.members}   🏆 ${g.trophies}',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('➕ Unirse',
                    style: TextStyle(color: Colors.black)),
                onPressed: () async {
                  final res = await widget.api.joinGuild(g.id);
                  final msg = res['status'] == 'ok'
                      ? '✅ ¡Unido!'
                      : '❌ ' + (res['error'] ?? 'Error al unirse');
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(msg)));
                  if (res['status'] == 'ok') (context as Element).reassemble();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

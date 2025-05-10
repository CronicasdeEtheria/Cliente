// lib/screens/my_guild_view.dart

import 'package:flutter/material.dart';
import 'package:guild_client/services/api_service.dart';

/// Vista dedicada a "Mi Gremio": muestra datos y miembros en modo horizontal.
class MyGuildView extends StatelessWidget {
  final ApiService api;
  final String guildId;
  final String currentUser;
  static const int maxVisibleMembers = 20;

  const MyGuildView({
    Key? key,
    required this.api,
    required this.guildId,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FutureBuilder<Map<String, dynamic>>(
            future: api.getGuildInfo(guildId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                );
              }
              if (snap.hasError) {
                return Center(
                  child: Text(
                    '❌ Error: ${snap.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }
              final data = snap.data;
              if (data == null || data.isEmpty) {
                return const Center(
                  child: Text(
                    'No se encontraron datos del gremio',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              // Datos básicos
              final name = data['name'] as String? ?? '—';
              final description = data['description'] as String? ?? '';
              final trophies = data['trophies'] as int? ?? 0;
              final createdAtRaw = data['created_at'] as String?;
              String? createdAt;
              if (createdAtRaw != null) {
                final dt = DateTime.tryParse(createdAtRaw);
                if (dt != null) {
                  createdAt = '${dt.day.toString().padLeft(2, '0')}/'
                      '${dt.month.toString().padLeft(2, '0')}/'
                      '${dt.year}';
                }
              }
              final totalCount = data['member_count'] as int?;

              // Ordenar y limitar miembros
              final membersFull = List<Map<String, dynamic>>.from(
                data['members'] as List<dynamic>? ?? [],
              )
                ..sort(
                  (a, b) => (b['elo'] as int).compareTo(a['elo'] as int),
                );
              final members = membersFull.take(maxVisibleMembers).toList();

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel de información del gremio sin scroll extra
                  Flexible(
                    flex: 3,
                    child: Card(
                      color: Colors.grey[850],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(right: 12, bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen del gremio
                            Center(
                              child: CircleAvatar(
                                radius: 36,
                                backgroundImage: NetworkImage(
                                  '${api.baseUrl}/guild/image/$guildId',
                                ),
                                backgroundColor: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Nombre
                            Text(
                              '🏷️ $name',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Fecha de creación
                            if (createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Creado: $createdAt',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],

                            // Descripción acotada
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            // Trofeos
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$trophies trofeos',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Lista de miembros
                  Flexible(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          '👥 Miembros ' +
                              (totalCount != null
                                  ? '($maxVisibleMembers de $totalCount)'
                                  : ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(color: Colors.white24),

                        // Lista scrollable
                        Expanded(
                          child: ListView.separated(
                            itemCount: members.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Colors.white12),
                            itemBuilder: (context, index) {
                              final m = members[index];
                              final user = m['username'] as String;
                              final elo = m['elo'] as int;
                              final isLeader = m['is_leader'] as bool;

                              Widget? trailing;
                              if (user == currentUser) {
                                trailing = TextButton.icon(
                                  icon: const Icon(
                                    Icons.exit_to_app,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Salir',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () async {
                                    final res = await api.leaveGuild();
                                    final ok = res['status'] == 'left';
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? '👋 Saliste del gremio'
                                              :
                                                  "❌ ${res['error'] ?? 'Error al salir'}",
                                        ),
                                      ),
                                    );
                                    if (ok) Navigator.of(context).pop();
                                  },
                                );
                              } else if (isLeader) {
                                trailing = const Icon(
                                  Icons.star,
                                  color: Colors.yellowAccent,
                                );
                              }

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: user == currentUser
                                      ? Colors.orange
                                      : Colors.grey[700],
                                  child: Text(
                                    user.isNotEmpty ? user[0] : '',
                                    style: const TextStyle(
                                        color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  user,
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                                subtitle: Text(
                                  'ELO: $elo',
                                  style: const TextStyle(
                                      color: Colors.white60),
                                ),
                                trailing: trailing,
                              );
                            },
                          ),
                        ),

                        // Indicador de conteo
                        if (totalCount != null &&
                            totalCount > maxVisibleMembers) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Mostrando $maxVisibleMembers de $totalCount miembros',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

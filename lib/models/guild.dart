// lib/models/guild.dart

class Guild {
  final String id;
  final String name;
  final int members;
  final int trophies;

  Guild({
    required this.id,
    required this.name,
    required this.members,
    required this.trophies,
  });

  factory Guild.fromJson(Map<String, dynamic> json) => Guild(
        id: json['id'] as String,
        name: json['name'] as String,
        members: (json['member_count'] ?? json['members']) as int,
        trophies: (json['trophies'] ?? 0) as int,
      );
}

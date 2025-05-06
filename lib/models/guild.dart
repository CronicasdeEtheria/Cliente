class Guild {
  final String id;
  final String name;
  final int members;
  Guild({required this.id, required this.name, required this.members});
  factory Guild.fromJson(Map<String, dynamic> j) => Guild(
    id: j['id'],
    name: j['name'],
    members: j['members'] ?? 0,
  );
}

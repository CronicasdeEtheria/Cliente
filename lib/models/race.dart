class Race {
  final String id;
  final String displayName;
  Race({required this.id, required this.displayName});
  factory Race.fromJson(Map<String, dynamic> j) =>
    Race(id: j['id'], displayName: j['displayName']);
}

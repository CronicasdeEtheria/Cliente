/// Modelo de Raza expandido para Crónicas de Etheria
class Race {
  final String id;

  final String displayName;

  final String emoji;

  String get assetPath => 'assets/races/$id.png';

  Race({
    required this.id,
    required this.displayName,
    required this.emoji,
  });


  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      emoji: json['emoji'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'emoji': emoji,
      };
}

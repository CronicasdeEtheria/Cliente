// lib/models/unit.dart

class Unit {
  final String id;
  final String name;

  Unit({
    required this.id,
    required this.name,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

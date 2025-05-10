// lib/models/message.dart
class Message {
  final String user;
  final String text;
  final DateTime time;

  Message({required this.user, required this.text, required this.time});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    user: json['username'] as String,
    text: json['message'] as String,
    time: DateTime.parse(json['timestamp'] as String),
  );
}

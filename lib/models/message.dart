class Message {
  final String user;
  final String text;
  final DateTime time;
  Message({required this.user, required this.text, required this.time});
  factory Message.fromJson(Map<String, dynamic> j) => Message(
    user: j['user'],
    text: j['text'],
    time: DateTime.parse(j['time']),
  );
}

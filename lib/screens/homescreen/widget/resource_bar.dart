import 'package:flutter/material.dart';

class ResourceBar extends StatelessWidget {
  final Map<String, int> resources;
  final Map<String, int> prodHour;
  final Map<String, int> capacity;

  const ResourceBar({
    super.key,
    required this.resources,
    required this.prodHour,
    required this.capacity,
  });

  Widget _tile(BuildContext ctx, String k, String emoji) => GestureDetector(
        onTap: () => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Capacidad máx. $emoji: ${capacity[k]}'),
        )),
        child: Column(
          children: [
            Text('$emoji ${resources[k] ?? 0}',
                style: const TextStyle(fontSize: 11, color: Colors.white)),
            Text('+${prodHour[k]} /h',
                style: const TextStyle(fontSize: 8, color: Colors.white70)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _tile(context, 'food',  '🍖'),
          _tile(context, 'wood',  '🪵'),
          _tile(context, 'stone', '🪨'),
          _tile(context, 'gold',  '🪙'),
        ],
      ),
    );
  }
}

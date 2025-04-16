import 'package:flutter/material.dart';

class SeatStatusBar extends StatelessWidget {
  final String title;
  final int used;
  final int total;

  const SeatStatusBar({
    super.key,
    required this.title,
    required this.used,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : used / total;
    final isAvailable = used < total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(
              ratio >= 0.9 ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$used', style: const TextStyle(fontSize: 16)),
              Text('$total', style: const TextStyle(fontSize: 16)),
              if (used == 0)
                const Text('자유이용', style: TextStyle(color: Colors.red)),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}

// lib/widgets/kkaezam/seat_status_bar.dart

import 'package:flutter/material.dart';

class SeatStatusBar extends StatelessWidget {
  final String roomName;
  final int usedSeats;
  final int totalSeats;

  const SeatStatusBar({
    super.key,
    required this.roomName,
    required this.usedSeats,
    required this.totalSeats,
  });

  @override
  Widget build(BuildContext context) {
    final double usageRatio =
        totalSeats == 0 ? 0 : usedSeats / totalSeats.toDouble();
    final bool isFull = usedSeats >= totalSeats;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 열람실 이름
          Text(
            roomName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          // 좌석 사용률 바
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: usageRatio,
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull
                    ? Colors.red
                    : usageRatio > 0.7
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 사용 중 / 전체 좌석 수 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('사용 중: $usedSeats'), Text('총 좌석: $totalSeats')],
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}

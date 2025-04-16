import 'package:flutter/material.dart';
import '../../widgets/kkaezam/seat_box.dart';

class KkaezamSeatMapScreen extends StatelessWidget {
  final String roomName;
  final int totalSeats;

  const KkaezamSeatMapScreen({
    super.key,
    required this.roomName,
    required this.totalSeats,
  });

  @override
  Widget build(BuildContext context) {
    final List<int> availableSeats =
        List.generate(
          totalSeats,
          (i) => i + 1,
        ).where((n) => n % 4 != 0).toList();
    final List<int> freeSeats =
        List.generate(
          totalSeats,
          (i) => i + 1,
        ).where((n) => n % 5 == 0).toList();

    Color seatColor(int seatNumber) {
      if (freeSeats.contains(seatNumber)) return Colors.brown;
      if (availableSeats.contains(seatNumber)) return Colors.green;
      return Colors.purple;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(roomName),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: SingleChildScrollView(
        // ← 드래그 가능하게 만듦
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(totalSeats, (index) {
            final seatNumber = index + 1;
            return SeatBox(
              number: seatNumber,
              color: seatColor(seatNumber),
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$seatNumber번 좌석 선택')));
              },
            );
          }),
        ),
      ),
    );
  }
}

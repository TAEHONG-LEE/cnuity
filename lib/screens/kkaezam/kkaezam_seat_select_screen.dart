// lib/screens/kkaezam/kkaezam_seat_select_screen.dart
import 'package:flutter/material.dart';

class KkaezamSeatSelectScreen extends StatelessWidget {
  const KkaezamSeatSelectScreen({super.key});

  final List<String> seatStatuses = const [
    'available',
    'occupied',
    'available',
    'occupied',
    'available',
    'available',
    'occupied',
    'available',
    'occupied',
    'occupied',
    'available',
    'available',
    'available',
    'occupied',
    'available',
    'occupied',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('좌석 선택'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.builder(
          itemCount: seatStatuses.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final status = seatStatuses[index];
            final isAvailable = status == 'available';

            return GestureDetector(
              onTap: () {
                if (isAvailable) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('좌석 ${index + 1} 선택됨')),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green[300] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '좌석 ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

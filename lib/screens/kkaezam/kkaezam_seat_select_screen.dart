import 'package:flutter/material.dart';
import '../../widgets/kkaezam/seat_status_bar.dart';
import 'kkaezam_seat_map_screen.dart';

class KkaezamSeatSelectScreen extends StatelessWidget {
  KkaezamSeatSelectScreen({super.key});

  // 예시용: 열람실 리스트 + 사용 중 좌석 수 포함
  final List<Map<String, dynamic>> readingRooms = [
    {'name': 'B2층(L001~L204)', 'total': 204, 'used': 193},
    {'name': 'B2층(C001~C083)', 'total': 83, 'used': 72},
    {'name': '2층 제3열람실(1~413)', 'total': 413, 'used': 166},
    {'name': '2층 제3열람실(414~713)', 'total': 300, 'used': 273},
    {'name': '2층 제1열람실', 'total': 440, 'used': 95},
    {'name': '2층 제2열람실', 'total': 272, 'used': 51},
    {'name': '2층 제2열람실 노트북석', 'total': 32, 'used': 26},
    {'name': '1층 자유열람실', 'total': 223, 'used': 0},
    {'name': 'B1층 열람실', 'total': 88, 'used': 0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('열람실 선택'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: ListView.builder(
        itemCount: readingRooms.length,
        itemBuilder: (context, index) {
          final room = readingRooms[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => KkaezamSeatMapScreen(
                        roomName: room['name'],
                        totalSeats: room['total'],
                      ),
                ),
              );
            },
            child: SeatStatusBar(
              roomName: room['name'],
              usedSeats: room['used'],
              totalSeats: room['total'],
            ),
          );
        },
      ),
    );
  }
}

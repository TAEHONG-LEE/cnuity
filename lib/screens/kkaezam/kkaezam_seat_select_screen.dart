import 'package:flutter/material.dart';
import 'kkaezam_seat_map_screen.dart';

class KkaezamSeatSelectScreen extends StatelessWidget {
  KkaezamSeatSelectScreen({super.key});

  // 열람실 정보 리스트
  final List<Map<String, dynamic>> readingRooms = [
    {'name': 'B2층(L001~L204)', 'seatCount': 204},
    {'name': 'B2층(C001~C083)', 'seatCount': 83},
    {'name': '2층 제3열람실(1~413)', 'seatCount': 413},
    {'name': '2층 제3열람실(414~713)', 'seatCount': 300},
    {'name': '2층 제1열람실', 'seatCount': 440},
    {'name': '2층 제2열람실', 'seatCount': 272},
    {'name': '2층 제2열람실 노트북석', 'seatCount': 32},
    {'name': '1층 자유열람실', 'seatCount': 223},
    {'name': 'B1층 열람실', 'seatCount': 88},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('열람실 선택'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: ListView.separated(
        itemCount: readingRooms.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final room = readingRooms[index];
          return ListTile(
            title: Text(room['name']),
            subtitle: Text('좌석 수: ${room['seatCount']}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => KkaezamSeatMapScreen(
                        roomName: room['name'],
                        totalSeats: room['seatCount'],
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

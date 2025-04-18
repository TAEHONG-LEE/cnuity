import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeatInitializerScreen extends StatelessWidget {
  const SeatInitializerScreen({super.key});

  Future<void> _initializeSeats(BuildContext context) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final readingRooms = {
      'B2-L001-L204': {'name': 'B2층(L001~L204)', 'total': 204},
      'B2-C001-C083': {'name': 'B2층(C001~C083)', 'total': 83},
      '2F_third_room_1_413': {'name': '2층 제3열람실(1~413)', 'total': 413},
      '2F_third_room_414_713': {'name': '2층 제3열람실(414~713)', 'total': 300},
      '2F_first_room': {'name': '2층 제1열람실', 'total': 440},
      '2F_second_room': {'name': '2층 제2열람실', 'total': 272},
      '2F_second_room_labtop': {'name': '2층 제2열람실 노트북석', 'total': 32},
    };

    for (final entry in readingRooms.entries) {
      final docId = entry.key;
      final roomData = entry.value;
      final roomRef = firestore.collection('reading_rooms').doc(docId);

      await roomRef.set({
        'name': roomData['name'],
        'totalSeats': roomData['total'],
        'usedSeats': 0,
      });

      final totalSeats = roomData['total'] as int;

      for (int i = 1; i <= totalSeats; i++) {
        final seatRef = roomRef.collection('seats').doc(i.toString());
        await seatRef.set({
          'status': 'available',
          'reservedBy': '',
          'seatId': i.toString(),
          'roomDocId': docId,
          'sleepStart': null,
          'sleepDuration': 0,
          'wokeBy': '',
          'result': '',
          'sleepSessionId': '',
          'pointsGiven': 0,
          'pointsRewardedToOther': 0,
          'isCompleted': false,
          'wakeTime': null,
          'wasWokenByOther': false,
        }, SetOptions(merge: true)); // 병합 옵션 추가
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 좌석이 초기화되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('좌석 초기화'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _initializeSeats(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: const Text(
            '모든 좌석 초기화',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

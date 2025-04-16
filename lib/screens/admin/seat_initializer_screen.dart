import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeatInitializerScreen extends StatelessWidget {
  const SeatInitializerScreen({super.key});

  Future<void> initSeats(String roomDocId, int totalSeats) async {
    final seatsRef = FirebaseFirestore.instance
        .collection('reading_rooms')
        .doc(roomDocId)
        .collection('seats');

    for (int i = 1; i <= totalSeats; i++) {
      await seatsRef.doc(i.toString()).set({'status': 'available'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('좌석 초기화')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await initSeats('B2-C001-C083', 83);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('초기화 완료')));
          },
          child: const Text('좌석 83개 자동 생성'),
        ),
      ),
    );
  }
}

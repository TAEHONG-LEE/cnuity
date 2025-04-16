import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeatInitializerScreen extends StatelessWidget {
  const SeatInitializerScreen({super.key});

  // 각 열람실 문서에 좌석 일괄 추가
  Future<void> initAllReadingRooms() async {
    final firestore = FirebaseFirestore.instance;
    final roomsRef = firestore.collection('reading_rooms');
    final roomsSnapshot = await roomsRef.get();

    for (final doc in roomsSnapshot.docs) {
      final docId = doc.id;
      final data = doc.data();
      final totalSeats = data['totalSeats'] ?? 0;

      final seatsRef = roomsRef.doc(docId).collection('seats');

      for (int i = 1; i <= totalSeats; i++) {
        await seatsRef.doc(i.toString()).set({'status': 'available'});
      }

      debugPrint('✅ $docId - 좌석 $totalSeats개 생성 완료');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('좌석 일괄 초기화')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await initAllReadingRooms();
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('모든 열람실 좌석 생성 완료')));
            }
          },
          child: const Text('모든 열람실 좌석 자동 생성'),
        ),
      ),
    );
  }
}

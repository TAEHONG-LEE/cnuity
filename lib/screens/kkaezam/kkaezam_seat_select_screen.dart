import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/kkaezam/seat_status_bar.dart';
import 'kkaezam_seat_map_screen.dart';

class KkaezamSeatSelectScreen extends StatelessWidget {
  const KkaezamSeatSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roomCollection = FirebaseFirestore.instance.collection(
      'reading_rooms',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('열람실 선택'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: roomCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('데이터를 불러오는 중 오류 발생'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? '이름 없음';
              final used = data['usedSeats'] ?? 0;
              final total = data['totalSeats'] ?? 0;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => KkaezamSeatMapScreen(
                            roomName: name,
                            totalSeats: total,
                            roomDocId: doc.id, // Firestore 문서 ID
                          ),
                    ),
                  );
                },
                child: SeatStatusBar(
                  roomName: name,
                  usedSeats: used,
                  totalSeats: total,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

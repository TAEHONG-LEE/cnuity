import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/kkaezam/seat_tile.dart';

class KkaezamSeatMapScreen extends StatelessWidget {
  final String roomName;
  final int totalSeats;
  final String roomDocId;

  const KkaezamSeatMapScreen({
    super.key,
    required this.roomName,
    required this.totalSeats,
    required this.roomDocId,
  });

  @override
  Widget build(BuildContext context) {
    final seatsRef = FirebaseFirestore.instance
        .collection('reading_rooms')
        .doc(roomDocId)
        .collection('seats');

    return Scaffold(
      appBar: AppBar(
        title: Text(roomName),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: seatsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('좌석 정보를 불러오는 중 오류 발생'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final seatDocs = snapshot.data!.docs;
          final seatMap = <int, Map<String, dynamic>>{};

          for (final doc in seatDocs) {
            final seatNum = int.tryParse(doc.id);
            final data = doc.data() as Map<String, dynamic>;
            if (seatNum != null) {
              seatMap[seatNum] = data;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: List.generate(totalSeats, (index) {
                final seatNumber = index + 1;
                final seatData =
                    seatMap[seatNumber] ??
                    {'status': 'available', 'reservedBy': ''};

                return SeatTile(
                  seatNumber: seatNumber,
                  seatData: seatData,
                  roomDocId: roomDocId,
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

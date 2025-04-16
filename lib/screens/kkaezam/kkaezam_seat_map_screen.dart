import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/kkaezam/seat_box.dart';

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
          final seatMap = <int, String>{};

          for (final doc in seatDocs) {
            final seatNum = int.tryParse(doc.id);
            final status = doc['status'];
            if (seatNum != null) {
              seatMap[seatNum] = status;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(totalSeats, (index) {
                final seatNumber = index + 1;
                final status = seatMap[seatNumber] ?? 'available';

                Color color;
                switch (status) {
                  case 'reserved':
                    color = Colors.purple;
                    break;
                  case 'free':
                    color = Colors.brown;
                    break;
                  default:
                    color = Colors.green;
                }

                return SeatBox(
                  number: seatNumber,
                  color: color,
                  onTap: () async {
                    final seatDoc = seatsRef.doc(seatNumber.toString());

                    await seatDoc.update({'status': 'reserved'});

                    await FirebaseFirestore.instance
                        .collection('reading_rooms')
                        .doc(roomDocId)
                        .update({'usedSeats': FieldValue.increment(1)});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$seatNumber번 좌석 예약됨')),
                    );
                  },
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

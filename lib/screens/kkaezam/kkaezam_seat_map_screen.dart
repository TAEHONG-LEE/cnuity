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

  Color seatColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'sleeping':
        return Colors.blue;
      case 'wake_waiting':
        return Colors.amber;
      case 'woken_by_self':
        return Colors.lightGreen;
      case 'woken_by_other':
        return Colors.deepPurple;
      case 'done':
        return Colors.grey;
      case 'free':
        return Colors.brown;
      default:
        return Colors.black;
    }
  }

  bool canReserve(String status) {
    return status == 'available';
  }

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

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: List.generate(totalSeats, (index) {
                final seatNumber = index + 1;
                final status = seatMap[seatNumber] ?? 'available';

                return SeatBox(
                  number: seatNumber,
                  color: seatColor(status),
                  onTap: () async {
                    if (!canReserve(status)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$seatNumber번 좌석은 예약할 수 없습니다. 상태: $status',
                          ),
                        ),
                      );
                      return;
                    }

                    await seatsRef.doc(seatNumber.toString()).update({
                      'status': 'reserved',
                    });

                    await FirebaseFirestore.instance
                        .collection('reading_rooms')
                        .doc(roomDocId)
                        .update({'usedSeats': FieldValue.increment(1)});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$seatNumber번 좌석 예약 완료')),
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seat_box.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SeatTile extends StatelessWidget {
  final int seatNumber;
  final Map<String, dynamic> seatData;
  final String roomDocId;

  const SeatTile({
    super.key,
    required this.seatNumber,
    required this.seatData,
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

  bool isReservedByMe(String reservedBy, String currentUid) =>
      reservedBy == currentUid;
  bool isReservedByOther(String reservedBy, String currentUid) =>
      reservedBy.isNotEmpty && reservedBy != currentUid;

  @override
  Widget build(BuildContext context) {
    final String status = seatData['status'] ?? 'available';
    final String reservedBy = seatData['reservedBy'] ?? '';
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    final seatsRef = FirebaseFirestore.instance
        .collection('reading_rooms')
        .doc(roomDocId)
        .collection('seats');

    final roomRef = FirebaseFirestore.instance
        .collection('reading_rooms')
        .doc(roomDocId);

    return SeatBox(
      number: seatNumber,
      color: seatColor(status),
      onTap: () async {
        if (currentUid == null) return;
        final seatRef = seatsRef.doc(seatNumber.toString());

        // 다른 사람이 예약했거나, 사용할 수 없는 상태
        if (isReservedByOther(reservedBy, currentUid) ||
            (status != 'available' &&
                !isReservedByMe(reservedBy, currentUid))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$seatNumber번 좌석은 선택할 수 없습니다. 상태: $status')),
          );
          return;
        }

        // 내가 예약한 좌석이면 → 반납
        if (isReservedByMe(reservedBy, currentUid)) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: Text('$seatNumber번 좌석 반납할까요?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await seatRef.update({
                          'status': 'available',
                          'reservedBy': '',
                        });
                        await roomRef.update({
                          'usedSeats': FieldValue.increment(-1),
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$seatNumber번 좌석 반납 완료')),
                        );
                      },
                      child: const Text('반납'),
                    ),
                  ],
                ),
          );
          return;
        }

        // 이미 다른 좌석 예약했는지 확인
        final existing =
            await seatsRef.where('reservedBy', isEqualTo: currentUid).get();
        if (existing.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 예약한 좌석이 있습니다. 하나의 좌석만 선택할 수 있습니다.'),
            ),
          );
          return;
        }

        // 예약 진행
        await seatRef.update({'status': 'reserved', 'reservedBy': currentUid});

        await roomRef.update({'usedSeats': FieldValue.increment(1)});

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$seatNumber번 좌석 예약 완료')));
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'seat_box.dart';

class SeatTile extends StatefulWidget {
  final int seatNumber;
  final Map<String, dynamic> seatData;
  final String roomDocId;

  const SeatTile({
    super.key,
    required this.seatNumber,
    required this.seatData,
    required this.roomDocId,
  });

  @override
  State<SeatTile> createState() => _SeatTileState();
}

class _SeatTileState extends State<SeatTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<Color> celebrationColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color seatColor(String status) {
    if (status == 'woken_by_self') {
      final double t = _controller.value * (celebrationColors.length - 1);
      final int index = t.floor();
      final double remain = t - index;
      final Color start = celebrationColors[index % celebrationColors.length];
      final Color end =
          celebrationColors[(index + 1) % celebrationColors.length];
      return Color.lerp(start, end, remain) ?? Colors.lightGreen;
    }
    switch (status) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'sleeping':
        return Colors.blue;
      case 'wake_waiting':
        return Colors.amber;
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

  Widget? statusOverlay(String status) {
    switch (status) {
      case 'sleeping':
        return const Icon(Icons.bed, color: Colors.white, size: 16);
      case 'wake_waiting':
        return const Icon(Icons.alarm, color: Colors.white, size: 16);
      case 'woken_by_other':
        return const Icon(Icons.notifications, color: Colors.white, size: 16);
      case 'woken_by_self':
        return const Icon(
          Icons.local_fire_department,
          color: Colors.redAccent,
          size: 18,
        );
      default:
        return null;
    }
  }

  bool isReservedByMe(String reservedBy, String currentUid) =>
      reservedBy == currentUid;
  bool isReservedByOther(String reservedBy, String currentUid) =>
      reservedBy.isNotEmpty && reservedBy != currentUid;

  @override
  Widget build(BuildContext context) {
    final String status = widget.seatData['status'] ?? 'available';
    final String reservedBy = widget.seatData['reservedBy'] ?? '';
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    final seatsRef = FirebaseFirestore.instance
        .collection('reading_rooms')
        .doc(widget.roomDocId)
        .collection('seats');

    final roomRef = FirebaseFirestore.instance
        .collection('reading_rooms')
        .doc(widget.roomDocId);

    final scale =
        status == 'wake_waiting'
            ? 1 + 0.1 * sin(_controller.value * 2 * pi)
            : 1.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: scale,
          child: SeatBox(
            number: widget.seatNumber,
            color: seatColor(status),
            overlay: statusOverlay(status),
            onTap: () async {
              if (currentUid == null) return;
              final seatRef = seatsRef.doc(widget.seatNumber.toString());

              if (isReservedByOther(reservedBy, currentUid) ||
                  (status != 'available' &&
                      !isReservedByMe(reservedBy, currentUid))) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${widget.seatNumber}번 좌석은 선택할 수 없습니다. 상태: $status',
                    ),
                  ),
                );
                return;
              }

              if (isReservedByMe(reservedBy, currentUid)) {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: Text('${widget.seatNumber}번 좌석 반납할까요?'),
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
                                'sleepStart': null,
                                'sleepDuration': 0,
                                'sleepSessionId': '',
                                'result': '',
                                'wokeBy': '',
                                'wakeTime': null,
                                'wasWokenByOther': false,
                                'pointsGiven': 0,
                                'pointsRewardedToOther': 0,
                                'isCompleted': false,
                              });
                              await roomRef.update({
                                'usedSeats': FieldValue.increment(-1),
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${widget.seatNumber}번 좌석 반납 완료',
                                  ),
                                ),
                              );
                            },
                            child: const Text('반납'),
                          ),
                        ],
                      ),
                );
                return;
              }

              final existing =
                  await seatsRef
                      .where('reservedBy', isEqualTo: currentUid)
                      .get();
              if (existing.docs.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('이미 예약한 좌석이 있습니다. 하나의 좌석만 선택할 수 있습니다.'),
                  ),
                );
                return;
              }

              await seatRef.update({
                'status': 'reserved',
                'reservedBy': currentUid,
                'sleepStart': null,
                'sleepDuration': 0,
                'sleepSessionId': '',
                'result': '',
                'wokeBy': '',
                'wakeTime': null,
                'wasWokenByOther': false,
                'pointsGiven': 0,
                'pointsRewardedToOther': 0,
                'isCompleted': false,
              });

              await roomRef.update({'usedSeats': FieldValue.increment(1)});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.seatNumber}번 좌석 예약 완료')),
              );
            },
          ),
        );
      },
    );
  }
}

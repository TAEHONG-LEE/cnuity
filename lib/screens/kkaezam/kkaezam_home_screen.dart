import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/service_square_button.dart';
import 'kkaezam_seat_select_screen.dart';
import 'kkaezam_sleep_timer_screen.dart';

class KkaezamHomeScreen extends StatelessWidget {
  KkaezamHomeScreen({super.key});

  Future<void> _returnSeatIfReserved(BuildContext context) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final roomsSnapshot =
        await FirebaseFirestore.instance.collection('reading_rooms').get();

    for (final roomDoc in roomsSnapshot.docs) {
      final seatSnapshot =
          await roomDoc.reference
              .collection('seats')
              .where('reservedBy', isEqualTo: uid)
              .limit(1)
              .get();

      if (seatSnapshot.docs.isNotEmpty) {
        final seatDoc = seatSnapshot.docs.first;
        final seatRef = seatDoc.reference;

        await seatRef.update({'status': 'available', 'reservedBy': ''});

        await roomDoc.reference.update({'usedSeats': FieldValue.increment(-1)});

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${seatDoc.id}번 좌석 반납 완료')));
        return;
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('현재 예약된 좌석이 없습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('깨잠! 홈'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // 좌석 선택
            ServiceSquareButton(
              label: '좌석 선택',
              icon: Icons.event_seat,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => KkaezamSeatSelectScreen()),
                );
              },
            ),
            // 미션
            ServiceSquareButton(
              label: '미션',
              icon: Icons.flag,
              onTap: () {
                // TODO: 미션 페이지로 이동
              },
            ),
            // 잠자기
            ServiceSquareButton(
              label: '잠자기',
              icon: Icons.bed,
              onTap: () async {
                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                if (currentUid == null) return;

                final snapshot =
                    await FirebaseFirestore.instance
                        .collectionGroup('seats')
                        .where('reservedBy', isEqualTo: currentUid)
                        .where('status', whereIn: ['reserved', 'sleeping'])
                        .get();

                if (snapshot.docs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('좌석을 먼저 예약해주세요.')),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const KkaezamSleepTimerScreen(),
                  ),
                );
              },
            ),
            // 나의 기록
            ServiceSquareButton(
              label: '나의 기록',
              icon: Icons.bar_chart,
              onTap: () {
                // TODO: 결과/기록 페이지로 이동
              },
            ),
            // 내 좌석 반납
            ServiceSquareButton(
              label: '내 좌석 반납',
              icon: Icons.refresh,
              onTap: () => _returnSeatIfReserved(context),
            ),
          ],
        ),
      ),
    );
  }
}

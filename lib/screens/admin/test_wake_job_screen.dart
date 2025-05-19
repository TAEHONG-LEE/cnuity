import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestWakeJobScreen extends StatefulWidget {
  const TestWakeJobScreen({super.key});

  @override
  State<TestWakeJobScreen> createState() => _TestWakeJobScreenState();
}

class _TestWakeJobScreenState extends State<TestWakeJobScreen> {
  // 🔴 실제 reading_rooms 하위 문서 ID
  final String roomId = '2F_first_room';

  // 🔴 테스트에 사용할 UID (Firestore users 컬렉션에 존재해야 함)
  final String sleeperUid = 'user1'; // 100번 자는 사람
  final String neighborUid = 'user2'; // 101번 알림 받을 사람

  String _result = '테스트 대기 중…';

  // 좌석 스키마 기본값
  Map<String, dynamic> _baseSeat(String seatId) => {
    'seatId': seatId,
    'roomDocId': roomId,
    'result': '',
    'sleepSessionId': '',
    'pointsGiven': 0,
    'pointsRewardedToOther': 0,
    'isCompleted': false,
    'wasWokenByOther': false,
    'wakeBy': '',
    'wakeTime': Timestamp.fromDate(DateTime(1970)),
  };

  Future<void> _runTest() async {
    final fs = FirebaseFirestore.instance;
    final now = DateTime.now();
    final sleepStart = now.subtract(const Duration(minutes: 45));

    // === 좌석 100 (sleeping) ==========================================
    final seat100 = {
      ..._baseSeat('100'),
      'status': 'sleeping',
      'sleepStart': Timestamp.fromDate(sleepStart),
      'sleepDuration': 1800,
      'reservedBy': sleeperUid,
    };

    // === 좌석 101 (reserved) ==========================================
    final seat101 = {
      ..._baseSeat('101'),
      'status': 'reserved',
      'reservedBy': neighborUid,
    };

    // Firestore 저장
    await fs
        .collection('reading_rooms')
        .doc(roomId)
        .collection('seats')
        .doc('100')
        .set(seat100);
    await fs
        .collection('reading_rooms')
        .doc(roomId)
        .collection('seats')
        .doc('101')
        .set(seat101);

    setState(() => _result = '좌석 문서 생성 완료 ➜ 알림 대기 중…');

    // wakeReminderJob 은 최대 5분 내 실행 → 90초 대기
    await Future.delayed(const Duration(seconds: 90));

    // user2 알림 존재 확인
    final snap =
        await fs
            .collection('users')
            .doc(neighborUid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

    if (snap.docs.isEmpty) {
      setState(() => _result = '❌ 알림 수신 실패 (문서 없음)');
      return;
    }

    final data = snap.docs.first.data();
    if (data['targetSeat'] == '100') {
      setState(() => _result = '✅ 알림 정상 수신 (seat 100)');
    } else {
      setState(() => _result = '⚠️ 알림은 있지만 seat ID 불일치');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WakeReminderJob 자동 테스트')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: _runTest, child: const Text('테스트 실행')),
            const SizedBox(height: 32),
            Text(_result, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

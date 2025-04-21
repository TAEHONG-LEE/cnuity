// lib/widgets/kkaezam/wake_up_button.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WakeUpButton extends StatelessWidget {
  final VoidCallback? onComplete;

  const WakeUpButton({super.key, this.onComplete});

  Future<void> _handleWakeUp(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final seatsSnapshot =
        await FirebaseFirestore.instance
            .collectionGroup('seats')
            .where('reservedBy', isEqualTo: uid)
            .where('status', isEqualTo: 'sleeping')
            .limit(1)
            .get();

    if (seatsSnapshot.docs.isEmpty) return;

    final seatDoc = seatsSnapshot.docs.first;
    final seatRef = seatDoc.reference;
    final seatData = seatDoc.data();

    final startTime = (seatData['sleepStart'] as Timestamp).toDate();
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inSeconds;
    final sleepDuration = seatData['sleepDuration'] ?? 0;

    // Firestore 업데이트
    await seatRef.update({
      'status': 'woken_by_self',
      'wakeTime': Timestamp.fromDate(endTime),
      'isCompleted': true,
      'wasWokenByOther': false,
    });

    // 세션 저장
    final sessionId =
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sleep_sessions')
            .doc()
            .id;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sleep_sessions')
        .doc(sessionId)
        .set({
          'sessionId': sessionId,
          'seatId': seatData['seatId'],
          'startTime': seatData['sleepStart'],
          'endTime': Timestamp.fromDate(endTime),
          'sleepDuration': sleepDuration,
          'result': '스스로 기상',
          'pointsGiven': 5,
          'pointsRewardedToOther': 0,
          'wokeBy': uid,
        });

    // 유저 포인트 반영
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await userRef.update({
      'point': FieldValue.increment(5),
      'totalSleepTime': FieldValue.increment(duration),
      'totalSessions': FieldValue.increment(1),
      'selfWakeCount': FieldValue.increment(1),
      'lastSessionId': sessionId,
      'totalEarnedPoints': FieldValue.increment(5),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('잘 일어나셨습니다! +5P')));

    onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handleWakeUp(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text('일어나기'),
    );
  }
}

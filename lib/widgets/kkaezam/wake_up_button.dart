import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WakeUpButton extends StatefulWidget {
  final VoidCallback onComplete;

  const WakeUpButton({super.key, required this.onComplete});

  @override
  State<WakeUpButton> createState() => _WakeUpButtonState();
}

class _WakeUpButtonState extends State<WakeUpButton> {
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  bool _isProcessing = false;

  Future<void> _handleWakeUp() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final seatSnapshot =
        await FirebaseFirestore.instance
            .collectionGroup('seats')
            .where('reservedBy', isEqualTo: uid)
            .where('status', isEqualTo: 'sleeping')
            .limit(1)
            .get();

    if (seatSnapshot.docs.isNotEmpty) {
      final seatDoc = seatSnapshot.docs.first;
      final seatRef = seatDoc.reference;
      final seatData = seatDoc.data();
      final String seatId = seatData['seatId'] ?? seatDoc.id;
      final String roomDocId = seatData['roomDocId'] ?? 'unknown';
      final Timestamp startTime = seatData['sleepStart'];
      final int sleepDuration = seatData['sleepDuration'];

      final Timestamp endTime = Timestamp.now();
      final int actualDuration =
          endTime.toDate().difference(startTime.toDate()).inSeconds;

      final int pointsToRestore = sleepDuration ~/ 60;

      // 1. 좌석 상태 업데이트
      await seatRef.update({
        'status': 'woken_by_self',
        'wakeTime': endTime,
        'wasWokenByOther': false,
        'isCompleted': true,
      });

      // 2. 유저 sleep_sessions 기록 추가
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final sessionRef = userRef.collection('sleep_sessions').doc();

      await sessionRef.set({
        'sessionId': sessionRef.id,
        'seatId': seatId,
        'roomDocId': roomDocId,
        'startTime': startTime,
        'endTime': endTime,
        'sleepDuration': sleepDuration,
        'actualDuration': actualDuration,
        'result': '스스로 기상',
        'pointsGiven': pointsToRestore,
        'pointsRewardedToOther': 0,
      });

      // 3. 유저 요약 정보 업데이트
      await userRef.update({
        'point': FieldValue.increment(pointsToRestore),
        'totalEarnedPoints': FieldValue.increment(pointsToRestore),
        'totalSleepTime': FieldValue.increment(actualDuration),
        'totalSessions': FieldValue.increment(1),
        'selfWakeCount': FieldValue.increment(1),
        'lastSessionId': sessionRef.id,
      });

      // 4. 빵빠레 실행
      _confettiController.play();
      await Future.delayed(const Duration(seconds: 3));
      widget.onComplete();
    }

    setState(() => _isProcessing = false);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _handleWakeUp,
          icon: const Icon(Icons.sunny),
          label: const Text('일어나기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 20,
          emissionFrequency: 0.05,
          gravity: 0.2,
        ),
      ],
    );
  }
}

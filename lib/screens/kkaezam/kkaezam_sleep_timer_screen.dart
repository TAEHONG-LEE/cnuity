import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KkaezamSleepTimerScreen extends StatefulWidget {
  const KkaezamSleepTimerScreen({super.key});

  @override
  State<KkaezamSleepTimerScreen> createState() =>
      _KkaezamSleepTimerScreenState();
}

class _KkaezamSleepTimerScreenState extends State<KkaezamSleepTimerScreen> {
  static const int totalTime = 30 * 60; // 30분 (초 단위)
  int remainingTime = totalTime;
  Timer? timer;
  bool alreadySleeping = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    markSeatAsSleeping();
  }

  Future<void> markSeatAsSleeping() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collectionGroup('seats')
            .where('reservedBy', isEqualTo: uid)
            .where('status', whereIn: ['reserved', 'sleeping'])
            .get();

    if (snapshot.docs.isNotEmpty) {
      final seatDoc = snapshot.docs.first;

      // 이미 sleeping이면 다시 update하지 않음
      if (seatDoc['status'] == 'sleeping') {
        alreadySleeping = true;
        return;
      }

      await seatDoc.reference.update({'status': 'sleeping'});
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingTime <= 0) {
        t.cancel();
        onTimerComplete();
      } else {
        setState(() {
          remainingTime--;
        });
      }
    });
  }

  void onTimerComplete() {
    // TODO: 타이머 완료 후 Firestore에 상태 업데이트 & 결과 화면 이동
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('타이머가 완료되었습니다!')));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('잠자기 타이머'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '남은 시간',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              formatTime(remainingTime),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

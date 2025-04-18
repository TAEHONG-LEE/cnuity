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
  int sleepDuration = 30 * 60; // 기본 30분 (초)
  int elapsedTime = 0;
  Timer? timer;
  bool isSleeping = false;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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
      if (seatDoc['status'] != 'sleeping') {
        await seatDoc.reference.update({'status': 'sleeping'});
      }
    }
  }

  void startSleep() async {
    await markSeatAsSleeping();
    setState(() {
      isSleeping = true;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        elapsedTime++;
      });
    });
  }

  String formatTimer() {
    final delta = sleepDuration - elapsedTime;
    final sign = delta < 0 ? '+' : '-';
    final abs = delta.abs();
    final m = abs ~/ 60;
    final s = abs % 60;
    return '$sign${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void adjustSleepTime(int deltaMinutes) {
    setState(() {
      sleepDuration = (sleepDuration + deltaMinutes * 60).clamp(60, 120 * 60);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('잠자기 타이머'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isSleeping) ...[
                const Text('얼마나 잘까요?', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 16),
                Text(
                  '${sleepDuration ~/ 60}분',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => adjustSleepTime(-10),
                      child: const Text('-10분'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => adjustSleepTime(10),
                      child: const Text('+10분'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: startSleep,
                  child: const Text('잠자기 시작'),
                ),
              ] else ...[
                const Text('현재 상태', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 20),
                Text(
                  formatTimer(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// lib/screens/kkaezam/kkaezam_sleep_timer_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KkaezamSleepTimerScreen extends StatefulWidget {
  const KkaezamSleepTimerScreen({super.key});

  @override
  State<KkaezamSleepTimerScreen> createState() =>
      _KkaezamSleepTimerScreenState();
}

class _KkaezamSleepTimerScreenState extends State<KkaezamSleepTimerScreen>
    with SingleTickerProviderStateMixin {
  int sleepDuration = 30 * 60; // 기본 30분 (초)
  int elapsedTime = 0;
  Timer? timer;
  bool isSleeping = false;
  bool hasWokenUp = false;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _checkExistingSleepStatus();
  }

  Future<void> _checkExistingSleepStatus() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collectionGroup('seats')
            .where('reservedBy', isEqualTo: uid)
            .where('status', whereIn: ['sleeping', 'woken_by_self'])
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = doc.data();

      final Timestamp? start = data['sleepStart'];
      final int duration = data['sleepDuration'];

      final int elapsed =
          start == null
              ? 0
              : DateTime.now()
                  .difference(start.toDate())
                  .inSeconds
                  .clamp(0, duration * 2);

      setState(() {
        isSleeping = true;
        sleepDuration = duration;
        elapsedTime = elapsed;
        hasWokenUp = data['status'] == 'woken_by_self';
      });
      _startTimer();
    }
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        elapsedTime++;
      });
    });
  }

  Future<void> _startSleep() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collectionGroup('seats')
            .where('reservedBy', isEqualTo: uid)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      await doc.reference.update({
        'status': 'sleeping',
        'sleepStart': Timestamp.now(),
        'sleepDuration': sleepDuration,
      });
    }

    setState(() {
      isSleeping = true;
      elapsedTime = 0;
    });
    _startTimer();
  }

  Future<void> _wakeUp() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collectionGroup('seats')
            .where('reservedBy', isEqualTo: uid)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      await doc.reference.update({
        'status': 'woken_by_self',
        'wakeTime': Timestamp.now(),
      });
    }

    setState(() {
      hasWokenUp = true;
    });
    _confettiController.forward(from: 0);
  }

  String _formatTimer() {
    final delta = sleepDuration - elapsedTime;
    final sign = delta < 0 ? '+' : '-';
    final abs = delta.abs();
    final m = abs ~/ 60;
    final s = abs % 60;
    return '$sign${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _adjustSleepTime(int deltaMinutes) {
    setState(() {
      sleepDuration = (sleepDuration + deltaMinutes * 60).clamp(60, 120 * 60);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _confettiController.dispose();
    super.dispose();
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
                      onPressed: () => _adjustSleepTime(-10),
                      child: const Text('-10분'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => _adjustSleepTime(10),
                      child: const Text('+10분'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _startSleep,
                  child: const Text('잠자기 시작'),
                ),
              ] else ...[
                const Text('현재 상태', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 20),
                Text(
                  _formatTimer(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                if (!hasWokenUp)
                  ElevatedButton(onPressed: _wakeUp, child: const Text('일어나기')),
                if (hasWokenUp)
                  Column(
                    children: [
                      const Text(
                        '잘 일어나셨어요! 🎉',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _confettiController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _confettiController.value * 2 * pi,
                            child: const Icon(
                              Icons.celebration,
                              color: Colors.amber,
                              size: 64,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

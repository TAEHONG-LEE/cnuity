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
  int sleepDuration = 30 * 60; // 기본 30분
  int elapsedTime = 0;
  Timer? timer;
  bool isSleeping = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSleepStatus();
  }

  Future<void> _checkExistingSleepStatus() async {
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
      final data = doc.data();

      if (data['status'] == 'sleeping') {
        final Timestamp start = data['sleepStart'];
        final int duration = data['sleepDuration'];
        final int elapsed = DateTime.now()
            .difference(start.toDate())
            .inSeconds
            .clamp(0, duration * 2);
        setState(() {
          isSleeping = true;
          sleepDuration = duration;
          elapsedTime = elapsed;
        });
        _startTimer();
      }
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
      sleepDuration = (sleepDuration + deltaMinutes * 60).clamp(60, 7200);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

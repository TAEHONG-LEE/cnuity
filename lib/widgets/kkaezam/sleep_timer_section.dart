// lib/widgets/kkaezam/sleep_timer_section.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'qr_wake_button.dart';

class SleepTimerSection extends StatefulWidget {
  final VoidCallback onFinish;

  const SleepTimerSection({super.key, required this.onFinish});

  @override
  State<SleepTimerSection> createState() => _SleepTimerSectionState();
}

class _SleepTimerSectionState extends State<SleepTimerSection> {
  int sleepDuration = 30 * 60; // 기본 30분
  int elapsedTime = 0;
  Timer? timer;
  bool isSleeping = false;
  DateTime? sleepStartTime;

  @override
  void initState() {
    super.initState();
    _checkExistingSleepStatus();
  }

  Future<void> _checkExistingSleepStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collectionGroup('seats')
            .where('reservedBy', isEqualTo: uid)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      if (data['status'] == 'sleeping') {
        final Timestamp start = data['sleepStart'];
        final int duration = data['sleepDuration'];
        sleepStartTime = start.toDate();

        setState(() {
          isSleeping = true;
          sleepDuration = duration;
        });
        _startTimer();
      }
    }
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (sleepStartTime == null) return;
      final now = DateTime.now();
      setState(() {
        elapsedTime = now.difference(sleepStartTime!).inSeconds;
      });
    });
  }

  Future<void> _startSleep() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userSnapshot = await userRef.get();
    final int currentPoint = userSnapshot['point'] ?? 0;

    final snapshot =
        await FirebaseFirestore.instance
            .collectionGroup('seats')
            .where('reservedBy', isEqualTo: uid)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final seatDoc = snapshot.docs.first;
      final seatRef = seatDoc.reference;

      final int requiredPoints =
          sleepDuration <= 1800 ? 10 : (sleepDuration / 60).ceil();

      if (currentPoint < requiredPoints) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('포인트가 부족합니다. (${requiredPoints}P 필요)')),
        );
        return;
      }

      final now = DateTime.now();
      await seatRef.update({
        'status': 'sleeping',
        'sleepStart': Timestamp.fromDate(now),
        'sleepDuration': sleepDuration,
      });

      await userRef.update({
        'point': currentPoint - requiredPoints,
        'totalUsedPoints': FieldValue.increment(requiredPoints),
      });

      sleepStartTime = now;
      isSleeping = true;
      _startTimer();
      setState(() {});
      _startTimer();
    }
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
    final bool canWakeUp = isSleeping && elapsedTime >= sleepDuration;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isSleeping) ...[
          const Text('얼마나 잘까요?', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Text(
            '${sleepDuration ~/ 60}분',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
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
            onPressed: isSleeping ? null : _startSleep,
            child: const Text('잠자기 시작'),
          ),
        ] else ...[
          const Text('현재 상태', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          Text(
            _formatTimer(),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (canWakeUp) QrWakeButton(onComplete: widget.onFinish),
        ],
      ],
    );
  }
}

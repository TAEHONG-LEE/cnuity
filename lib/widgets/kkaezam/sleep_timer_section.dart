// lib/widgets/kkaezam/sleep_timer_section.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'qr_wake_button.dart'; // ✅ QR 기상 버튼 import

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

      // ✅ 목표 수면시간에 따라 필요한 포인트 계산
      final int requiredPoints =
          sleepDuration <= 1800 ? 10 : (sleepDuration / 60).ceil();

      if (currentPoint < requiredPoints) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('포인트가 부족합니다. (${requiredPoints}P 필요)')),
        );
        return;
      }

      // ✅ 좌석 상태 업데이트
      await seatRef.update({
        'status': 'sleeping',
        'sleepStart': Timestamp.now(),
        'sleepDuration': sleepDuration,
      });

      // ✅ 포인트 차감 (예약 비용)
      await userRef.update({
        'point': currentPoint - requiredPoints,
        'totalUsedPoints': FieldValue.increment(requiredPoints),
      });

      setState(() {
        isSleeping = true;
        elapsedTime = 0;
      });
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
          ElevatedButton(onPressed: _startSleep, child: const Text('잠자기 시작')),
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

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'wake_up_button.dart';

// class SleepTimerSection extends StatefulWidget {
//   final VoidCallback onFinish;

//   const SleepTimerSection({super.key, required this.onFinish});

//   @override
//   State<SleepTimerSection> createState() => _SleepTimerSectionState();
// }

// class _SleepTimerSectionState extends State<SleepTimerSection> {
//   int sleepDuration = 30 * 60;
//   int elapsedTime = 0;
//   Timer? timer;
//   bool isSleeping = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkExistingSleepStatus();
//   }

//   Future<void> _checkExistingSleepStatus() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;

//     final snapshot =
//         await FirebaseFirestore.instance
//             .collectionGroup('seats')
//             .where('reservedBy', isEqualTo: uid)
//             .limit(1)
//             .get();

//     if (snapshot.docs.isNotEmpty) {
//       final data = snapshot.docs.first.data();
//       if (data['status'] == 'sleeping') {
//         final Timestamp start = data['sleepStart'];
//         final int duration = data['sleepDuration'];
//         final int elapsed = DateTime.now()
//             .difference(start.toDate())
//             .inSeconds
//             .clamp(0, duration * 2);

//         setState(() {
//           isSleeping = true;
//           sleepDuration = duration;
//           elapsedTime = elapsed;
//         });
//         _startTimer();
//       }
//     }
//   }

//   void _startTimer() {
//     timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       setState(() {
//         elapsedTime++;
//       });
//     });
//   }

//   Future<void> _startSleep() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;

//     final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
//     final userSnapshot = await userRef.get();
//     final int currentPoint = userSnapshot['point'] ?? 0;

//     final snapshot =
//         await FirebaseFirestore.instance
//             .collectionGroup('seats')
//             .where('reservedBy', isEqualTo: uid)
//             .limit(1)
//             .get();

//     if (snapshot.docs.isNotEmpty) {
//       final seatDoc = snapshot.docs.first;
//       final seatRef = seatDoc.reference;

//       final int requiredPoints = (sleepDuration / 60).ceil(); // 1분당 1포인트

//       if (currentPoint < requiredPoints) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('포인트가 부족합니다. (${requiredPoints}P 필요)')),
//         );
//         return;
//       }

//       await seatRef.update({
//         'status': 'sleeping',
//         'sleepStart': Timestamp.now(),
//         'sleepDuration': sleepDuration,
//       });

//       await userRef.update({
//         'point': currentPoint - requiredPoints,
//         'totalUsedPoints': FieldValue.increment(requiredPoints),
//       });

//       setState(() {
//         isSleeping = true;
//         elapsedTime = 0;
//       });
//       _startTimer();
//     }
//   }

//   String _formatTimer() {
//     final delta = sleepDuration - elapsedTime;
//     final sign = delta < 0 ? '+' : '-';
//     final abs = delta.abs();
//     final m = abs ~/ 60;
//     final s = abs % 60;
//     return '$sign${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
//   }

//   void _adjustSleepTime(int deltaMinutes) {
//     setState(() {
//       sleepDuration = (sleepDuration + deltaMinutes * 60).clamp(60, 7200);
//     });
//   }

//   @override
//   void dispose() {
//     timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool canWakeUp = isSleeping && elapsedTime >= sleepDuration;

//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         if (!isSleeping) ...[
//           const Text('얼마나 잘까요?', style: TextStyle(fontSize: 24)),
//           const SizedBox(height: 16),
//           Text(
//             '${sleepDuration ~/ 60}분',
//             style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton(
//                 onPressed: () => _adjustSleepTime(-10),
//                 child: const Text('-10분'),
//               ),
//               const SizedBox(width: 20),
//               ElevatedButton(
//                 onPressed: () => _adjustSleepTime(10),
//                 child: const Text('+10분'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 30),
//           ElevatedButton(onPressed: _startSleep, child: const Text('잠자기 시작')),
//         ] else ...[
//           const Text('현재 상태', style: TextStyle(fontSize: 24)),
//           const SizedBox(height: 20),
//           Text(
//             _formatTimer(),
//             style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 20),
//           if (canWakeUp) WakeUpButton(onComplete: widget.onFinish),
//         ],
//       ],
//     );
//   }
// }

// lib/widgets/kkaezam/qr_wake_button.dart

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:cnuity/screens/kkaezam/qr/scan_qr_screen.dart';

class QrWakeButton extends StatefulWidget {
  final VoidCallback? onComplete;

  const QrWakeButton({super.key, this.onComplete});

  @override
  State<QrWakeButton> createState() => _QrWakeButtonState();
}

class _QrWakeButtonState extends State<QrWakeButton> {
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  bool _isProcessing = false;

  Future<void> _openScannerAndHandleResult() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // QR 스캔 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanQrScreen()),
    );

    // 스캔 후 성공 여부에 따라 후처리
    if (result == 'wake_success') {
      _confettiController.play();
      await Future.delayed(const Duration(seconds: 2));
      widget.onComplete?.call();
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
          onPressed: _isProcessing ? null : _openScannerAndHandleResult,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('QR로 기상 인증'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5197FF),
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

// // lib/widgets/kkaezam/qr_wake_button.dart

// import 'package:confetti/confetti.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class QrWakeButton extends StatefulWidget {
//   final VoidCallback? onComplete;

//   const QrWakeButton({super.key, this.onComplete});

//   @override
//   State<QrWakeButton> createState() => _QrWakeButtonState();
// }

// class _QrWakeButtonState extends State<QrWakeButton> {
//   final ConfettiController _confettiController = ConfettiController(
//     duration: const Duration(seconds: 2),
//   );

//   bool _isProcessing = false;

//   Future<void> _handleWakeUp() async {
//     if (_isProcessing) return;
//     setState(() => _isProcessing = true);

//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;

//     final seatSnapshot =
//         await FirebaseFirestore.instance
//             .collectionGroup('seats')
//             .where('reservedBy', isEqualTo: uid)
//             .where('status', isEqualTo: 'sleeping')
//             .limit(1)
//             .get();

//     if (seatSnapshot.docs.isNotEmpty) {
//       final seatDoc = seatSnapshot.docs.first;
//       final seatRef = seatDoc.reference;
//       final seatData = seatDoc.data();
//       final String seatId = seatData['seatId'] ?? seatDoc.id;
//       final String roomDocId = seatData['roomDocId'] ?? 'unknown';
//       final Timestamp startTime = seatData['sleepStart'];
//       final int sleepDuration = seatData['sleepDuration'];

//       final Timestamp endTime = Timestamp.now();
//       final int actualDuration =
//           endTime.toDate().difference(startTime.toDate()).inSeconds;

//       final int pointsToRestore = sleepDuration ~/ 60;

//       // 1. 좌석 상태 업데이트
//       await seatRef.update({
//         'status': 'woken_by_self',
//         'wakeTime': endTime,
//         'wasWokenByOther': false,
//         'isCompleted': true,
//       });

//       // 2. 유저 sleep_sessions 기록 추가
//       final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
//       final sessionRef = userRef.collection('sleep_sessions').doc();

//       await sessionRef.set({
//         'sessionId': sessionRef.id,
//         'seatId': seatId,
//         'roomDocId': roomDocId,
//         'startTime': startTime,
//         'endTime': endTime,
//         'sleepDuration': sleepDuration,
//         'actualDuration': actualDuration,
//         'result': '스스로 기상',
//         'pointsGiven': pointsToRestore,
//         'pointsRewardedToOther': 0,
//       });

//       // 3. 유저 요약 정보 업데이트
//       await userRef.update({
//         'point': FieldValue.increment(pointsToRestore),
//         'totalEarnedPoints': FieldValue.increment(pointsToRestore),
//         'totalSleepTime': FieldValue.increment(actualDuration),
//         'totalSessions': FieldValue.increment(1),
//         'selfWakeCount': FieldValue.increment(1),
//         'lastSessionId': sessionRef.id,
//       });

//       // 4. 빵빠레 실행 및 콜백
//       _confettiController.play();
//       await Future.delayed(const Duration(seconds: 2));
//       widget.onComplete?.call();
//     }

//     setState(() => _isProcessing = false);
//   }

//   @override
//   void dispose() {
//     _confettiController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         ElevatedButton.icon(
//           onPressed: _isProcessing ? null : _handleWakeUp,
//           icon: const Icon(Icons.qr_code_scanner),
//           label: const Text('QR로 기상 인증'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF5197FF),
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//           ),
//         ),
//         ConfettiWidget(
//           confettiController: _confettiController,
//           blastDirectionality: BlastDirectionality.explosive,
//           shouldLoop: false,
//           numberOfParticles: 20,
//           emissionFrequency: 0.05,
//           gravity: 0.2,
//         ),
//       ],
//     );
//   }
// }

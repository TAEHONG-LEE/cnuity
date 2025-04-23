// lib/screens/kkaezam/qr/scan_qr_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/qr_helper.dart';

class ScanQrScreen extends StatelessWidget {
  const ScanQrScreen({super.key});

  Future<void> _logPointChange({
    required String uid,
    required int delta,
    required String reason,
  }) async {
    final logRef =
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('point_logs')
            .doc();

    await logRef.set({
      'logId': logRef.id,
      'delta': delta,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleScan(
    String? rawData,
    BuildContext context,
    MobileScannerController controller,
  ) async {
    if (rawData == null) return;

    try {
      final Map<String, dynamic> data = QrHelper.decodeQrData(rawData);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = Timestamp.now();
      final int nowSeconds = now.seconds;

      // 🔒 유효 시간 체크
      final Timestamp generatedAt = data['generatedAt'];
      if (nowSeconds - generatedAt.seconds > 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR 코드가 만료되었습니다. 다시 생성해주세요.')),
        );
        return;
      }

      final String type = data['type'];
      final String seatId = data['seatId'];
      final String roomDocId = data['roomDocId'];
      final String scannedUid = data['uid'];
      final String sessionId = data['sleepSessionId'];
      final String currentUid = user.uid;

      final seatRef = FirebaseFirestore.instance
          .collection('reading_rooms')
          .doc(roomDocId)
          .collection('seats')
          .doc(seatId);

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(scannedUid);
      final sessionRef = userRef.collection('sleep_sessions').doc(sessionId);

      if (type == 'wake_by_self' && scannedUid == currentUid) {
        final seatSnap = await seatRef.get();
        final seatData = seatSnap.data();
        final int sleepDuration = seatData?['sleepDuration'] ?? 0;
        final int points = sleepDuration ~/ 60;

        await seatRef.update({
          'status': 'woken_by_self',
          'wakeTime': now,
          'wasWokenByOther': false,
          'isCompleted': true,
        });

        await sessionRef.update({
          'wakeTime': now,
          'isCompleted': true,
          'result': '스스로 기상',
          'pointsRewardedToOther': 0,
        });

        await userRef.update({
          'selfWakeCount': FieldValue.increment(1),
          'point': FieldValue.increment(points),
          'totalEarnedPoints': FieldValue.increment(points),
        });

        await _logPointChange(
          uid: scannedUid,
          delta: points,
          reason: '스스로 기상 보상',
        );

        Navigator.pop(context, 'wake_success');
      } else if (type == 'wake_by_other' && scannedUid != currentUid) {
        final String wakerUid = currentUid;

        final seatSnap = await seatRef.get();
        final seatData = seatSnap.data();
        final Timestamp startTime = seatData?['sleepStart'] ?? Timestamp.now();
        final int sleepDuration = seatData?['sleepDuration'] ?? 0;
        final int secondsElapsed = nowSeconds - startTime.seconds;

        int pointsToWaker = 0;
        int pointsToUser = 0;

        if (secondsElapsed >= 1800) {
          pointsToWaker = 10;
          pointsToUser = 0;
        } else if (secondsElapsed >= 600) {
          pointsToWaker = 5;
          pointsToUser = 5;
        }

        await seatRef.update({
          'status': 'woken_by_other',
          'wakeTime': now,
          'wasWokenByOther': true,
          'isCompleted': true,
        });

        await sessionRef.update({
          'wakeTime': now,
          'isCompleted': true,
          'result': '타인에 의해 기상',
          'pointsRewardedToOther': pointsToWaker,
        });

        await userRef.update({
          'forcedWakeCount': FieldValue.increment(1),
          if (pointsToUser > 0) 'point': FieldValue.increment(pointsToUser),
          if (pointsToUser > 0)
            'totalEarnedPoints': FieldValue.increment(pointsToUser),
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(wakerUid)
            .update({
              'point': FieldValue.increment(pointsToWaker),
              'totalEarnedPoints': FieldValue.increment(pointsToWaker),
            });

        if (pointsToUser > 0) {
          await _logPointChange(
            uid: scannedUid,
            delta: pointsToUser,
            reason: '타인 기상 - 일부 보상 반환',
          );
        }

        await _logPointChange(
          uid: wakerUid,
          delta: pointsToWaker,
          reason: '타인 기상 보상',
        );

        Navigator.pop(context, 'wake_success');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('잘못된 QR 코드이거나 권한이 없습니다.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('QR 처리 실패: $e')));
    } finally {
      controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = MobileScannerController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR 스캔으로 기상 인증'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final rawValue = barcode.rawValue;
          _handleScan(rawValue, context, controller);
        },
      ),
    );
  }
}

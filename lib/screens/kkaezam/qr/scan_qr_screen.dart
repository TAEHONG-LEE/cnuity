// lib/screens/kkaezam/qr/scan_qr_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/qr_helper.dart';

class ScanQrScreen extends StatelessWidget {
  const ScanQrScreen({super.key});

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

      final String type = data['type'];
      final String seatId = data['seatId'];
      final String roomDocId = data['roomDocId'];

      final seatRef = FirebaseFirestore.instance
          .collection('reading_rooms')
          .doc(roomDocId)
          .collection('seats')
          .doc(seatId);

      final seatSnap = await seatRef.get();
      final seatData = seatSnap.data();
      if (seatData == null || seatData['reservedBy'] != user.uid) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('해당 좌석은 당신의 자리가 아닙니다.')));
        return;
      }

      final String sessionId = seatData['sleepSessionId'];
      final sessionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sleep_sessions')
          .doc(sessionId);

      final now = Timestamp.now();

      await seatRef.update({
        'status': type == 'wake_by_other' ? 'woken_by_other' : 'woken_by_self',
        'wakeTime': now,
        'wasWokenByOther': type == 'wake_by_other',
        'isCompleted': true,
      });

      final sessionUpdates = {
        'wakeTime': now,
        'isCompleted': true,
        'result': type == 'wake_by_other' ? '타인에 의해 기상' : '스스로 기상',
      };

      if (type == 'wake_by_other') {
        final wakerUid = data['wakerUid'];
        sessionUpdates['pointsRewardedToOther'] = 10;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(wakerUid)
            .update({
              'point': FieldValue.increment(10),
              'totalEarnedPoints': FieldValue.increment(10),
            });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'forcedWakeCount': FieldValue.increment(1)});
      } else {
        final int sleepDuration = seatData['sleepDuration'];
        final int pointsToRestore = sleepDuration ~/ 60;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'selfWakeCount': FieldValue.increment(1),
              'point': FieldValue.increment(pointsToRestore),
              'totalEarnedPoints': FieldValue.increment(pointsToRestore),
            });
      }

      await sessionRef.update(sessionUpdates);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('기상 처리 완료!')));
        Navigator.pop(context);
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

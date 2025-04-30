import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/qr_helper.dart';
import 'wake_result_screen.dart'; // ✅ WakeResultScreen 임포트

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  _ScanQrScreenState createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool isProcessing = false; // QR 스캔 처리 중인지 여부를 확인하는 플래그

  Future<void> _handleScan(
    String? rawData,
    BuildContext context,
    MobileScannerController controller,
  ) async {
    if (rawData == null || isProcessing) return; // 처리 중이면 아무것도 안 함

    setState(() {
      isProcessing = true; // 스캔 처리 시작
    });

    try {
      final Map<String, dynamic> data = QrHelper.decodeQrData(rawData);
      debugPrint('📦 받은 QR 데이터: $data');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final String type = data['type'];
      final String seatIdFromQr = data['seatId'] ?? '';
      final String roomDocIdFromQr = data['roomDocId'] ?? '';
      final String scannedUid = data['uid'];
      final String currentUid = user.uid;

      String seatId = seatIdFromQr;
      String roomDocId = roomDocIdFromQr;
      String seatName = '';
      DateTime sleepStart;
      DateTime wakeTime = DateTime.now();
      int sleepDuration;

      if (seatId.isEmpty || roomDocId.isEmpty) {
        final seatSnapshot =
            await FirebaseFirestore.instance
                .collectionGroup('seats')
                .where('reservedBy', isEqualTo: currentUid)
                .limit(1)
                .get();

        if (seatSnapshot.docs.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('현재 예약된 자리가 없습니다.')));
          return;
        }

        final seatDoc = seatSnapshot.docs.first;
        final seatData = seatDoc.data();
        seatId = seatData['seatId'] ?? '';
        roomDocId = seatDoc.reference.parent.parent?.id ?? '';
        sleepStart =
            (seatData['sleepStart'] as Timestamp?)?.toDate() ?? DateTime.now();
        sleepDuration = seatData['sleepDuration'] ?? 0;

        final roomSnap =
            await FirebaseFirestore.instance
                .collection('reading_rooms')
                .doc(roomDocId)
                .get();
        final roomData = roomSnap.data();
        final readingRoomName = roomData?['name'] ?? '알 수 없는 열람실';
        seatName = '$readingRoomName - $seatId번';

        await FirebaseFirestore.instance
            .collection('reading_rooms')
            .doc(roomDocId)
            .collection('seats')
            .doc(seatId)
            .update({
              'status': 'woken_by_self',
              'wakeTime': Timestamp.now(),
              'wasWokenByOther': false,
              'isCompleted': true,
            });
      } else {
        final seatRef = FirebaseFirestore.instance
            .collection('reading_rooms')
            .doc(roomDocId)
            .collection('seats')
            .doc(seatId);
        final seatSnap = await seatRef.get();
        final seatData = seatSnap.data();

        if (seatData == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('좌석 정보를 찾을 수 없습니다.')));
          return;
        }

        sleepStart =
            (seatData['sleepStart'] as Timestamp?)?.toDate() ?? DateTime.now();
        sleepDuration = seatData['sleepDuration'] ?? 0;

        final roomSnap =
            await FirebaseFirestore.instance
                .collection('reading_rooms')
                .doc(roomDocId)
                .get();
        final roomData = roomSnap.data();
        final readingRoomName = roomData?['name'] ?? '알 수 없는 열람실';
        seatName = '$readingRoomName - $seatId번';
      }

      // ✅ 수면 시간 계산 (분으로 변환)
      final int actualSleepMinutes = wakeTime.difference(sleepStart).inMinutes;
      final int targetSleepMinutes = sleepDuration ~/ 60;

      // ✅ 예약 시 차감했던 포인트 계산 (30분 이하 10P, 그 이상 1분당 차감)
      final int reservedPoints =
          sleepDuration <= 1800
              ? 10 // 30분 이하 예약 시 10포인트 차감
              : (sleepDuration - 1800); // 30분 초과 시, 초과분에 대해 1분당 차감

      int pointsDelta = 0;
      final int overSleepMinutes = actualSleepMinutes - targetSleepMinutes;

      if (overSleepMinutes >= 30) {
        pointsDelta = 0; // 30분 초과 시 복구 없음
      } else if (overSleepMinutes >= 10) {
        pointsDelta = 5; // 10분 초과 시 5포인트만 복구
      } else {
        pointsDelta = reservedPoints; // 목표 수면 내에서 수면 시 예약된 포인트 복구
      }

      // ✅ 포인트 차감 또는 복구가 중복되지 않도록 확인
      if (pointsDelta != 0) {
        final logRef =
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUid)
                .collection('point_logs')
                .doc();

        // 포인트 로그 기록
        await logRef.set({
          'logId': logRef.id,
          'delta': pointsDelta,
          'reason': pointsDelta > 0 ? '수면 목표 달성 포인트 복구' : '수면 목표 초과 벌점',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // ✅ Sleep Session 기록
      final sessionRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .collection('sleep_sessions')
              .doc();

      await sessionRef.set({
        'sessionId': sessionRef.id,
        'startTime': sleepStart,
        'endTime': wakeTime,
        'sleepDuration': sleepDuration,
        'actualDuration': wakeTime.difference(sleepStart).inSeconds,
        'result': type == 'wake_by_self' ? '스스로 기상' : '타인에 의해 기상',
        'pointsGiven': pointsDelta,
        'seatId': seatId,
        'roomDocId': roomDocId,
      });

      // ✅ User 문서 업데이트
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .update({
            'totalSleepTime': FieldValue.increment(
              wakeTime.difference(sleepStart).inSeconds,
            ),
            'totalSessions': FieldValue.increment(1),
            if (type == 'wake_by_self')
              'selfWakeCount': FieldValue.increment(1),
            if (type == 'wake_by_other')
              'forcedWakeCount': FieldValue.increment(1),
            'lastSessionId': sessionRef.id,
            if (pointsDelta > 0)
              'totalEarnedPoints': FieldValue.increment(pointsDelta),
            if (pointsDelta < 0)
              'totalUsedPoints': FieldValue.increment(pointsDelta.abs()),
            'point': FieldValue.increment(pointsDelta),
          });

      // ✅ WakeResultScreen 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => WakeResultScreen(
                seatName: seatName,
                resultType: type == 'wake_by_self' ? '스스로 기상' : '타인에 의해 기상',
                wakerNickname: type == 'wake_by_self' ? '본인' : '타인',
                sleepStart: sleepStart,
                wakeTime: wakeTime,
                sleepDuration: sleepDuration,
                pointsEarned: pointsDelta,
                actualSleepMinutes: actualSleepMinutes, // 실제 수면 시간 전달
                overSleepMinutes: overSleepMinutes, // 초과 수면 시간 전달
              ),
        ),
      );
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

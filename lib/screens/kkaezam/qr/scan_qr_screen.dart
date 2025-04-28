import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/qr_helper.dart';
import 'wake_result_screen.dart';

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

      // ✅ 고정 QR 처리
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

        // 🔥 열람실 이름 읽기
        final roomSnap =
            await FirebaseFirestore.instance
                .collection('reading_rooms')
                .doc(roomDocId)
                .get();
        final roomData = roomSnap.data();
        final readingRoomName = roomData?['name'] ?? '알 수 없는 열람실';
        seatName = '$readingRoomName - $seatId번';

        // 🔥 좌석 상태 업데이트 (스스로 기상)
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
      }
      // ✅ 일반 QR 처리
      else {
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

      // 🔥 수면 시간 계산
      final int actualSleepMinutes = wakeTime.difference(sleepStart).inMinutes;
      final int targetSleepMinutes = sleepDuration ~/ 60;

      // 🔥 포인트 차감 로직
      int pointsDelta = 0;
      final int overSleepMinutes = actualSleepMinutes - targetSleepMinutes;
      if (overSleepMinutes >= 30) {
        pointsDelta = -10;
      } else if (overSleepMinutes >= 10) {
        pointsDelta = -5;
      }

      // 🔥 Sleep Session 기록 생성
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

      // 🔥 User 문서 업데이트
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

      // 🔥 포인트 로그 추가
      if (pointsDelta != 0) {
        final logRef =
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUid)
                .collection('point_logs')
                .doc();
        await logRef.set({
          'logId': logRef.id,
          'delta': pointsDelta,
          'reason': pointsDelta > 0 ? '수면 완료 보상' : '수면 목표 초과 벌점',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

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

// lib/screens/kkaezam/qr/scan_qr_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/qr_helper.dart';
import 'wake_result_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  _ScanQrScreenState createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool isProcessing = false;

  Future<void> _handleScan(
    String? rawData,
    BuildContext context,
    MobileScannerController controller,
  ) async {
    if (rawData == null || isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final Map<String, dynamic> data = QrHelper.decodeQrData(rawData);
      final String? type = data['type'];

      if (type == 'wake_by_other') {
        await _handleWakeByOther(data, context);
      } else if (type == 'wake_by_self') {
        await _handleWakeBySelf(data, context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('지원되지 않는 QR 타입입니다.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('QR 처리 실패: $e')));
    } finally {
      controller.stop();
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _handleWakeByOther(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String currentUid = user.uid; // QR을 찍은 사람 (기상자)
    final String targetUid = data['wakerUid']; // QR 생성자 (깨운 사람)
    final String seatId = data['seatId'];
    final String roomDocId = data['roomDocId'];

    if (targetUid == currentUid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('자기 자신을 깨울 수 없습니다.')));
      return;
    }

    final sessionQuery =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .collection('sleep_sessions')
            .orderBy('startTime', descending: true)
            .limit(1)
            .get();

    if (sessionQuery.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수면 세션이 없습니다.')));
      return;
    }

    final sessionDoc = sessionQuery.docs.first;

    // 필수 필드 체크
    final sleepStart = (sessionDoc['startTime'] as Timestamp?)?.toDate();
    final int? sleepDuration = sessionDoc['sleepDuration'];

    if (sleepStart == null || sleepDuration == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('세션 정보가 올바르지 않습니다.')));
      return;
    }

    final wakeTime = DateTime.now();
    final actualSleepMinutes = wakeTime.difference(sleepStart).inMinutes;
    final int targetSleepMinutes = sleepDuration ~/ 60;
    final int reservedPoints =
        sleepDuration <= 1800 ? 10 : (sleepDuration - 1800);
    final int overSleepMinutes = actualSleepMinutes - targetSleepMinutes;

    int pointsRecovered = 0;
    int pointsToReward = 10; // ✅ 타인이 깨우면 항상 10포인트 지급

    if (overSleepMinutes <= 5) {
      pointsRecovered = reservedPoints;
    } else if (overSleepMinutes <= 15) {
      pointsRecovered = (reservedPoints * 0.8).round();
    } else if (overSleepMinutes <= 30) {
      pointsRecovered = (reservedPoints * 0.5).round();
    } else {
      pointsRecovered = 0;
    }

    await sessionDoc.reference.update({
      'endTime': Timestamp.fromDate(wakeTime),
      'actualDuration': wakeTime.difference(sleepStart).inSeconds,
      'result': 'wake_by_other',
      'pointsGiven': pointsRecovered,
      'pointsRewardedToOther': pointsToReward,
    });

    await FirebaseFirestore.instance
        .collection('reading_rooms')
        .doc(roomDocId)
        .collection('seats')
        .doc(seatId)
        .update({
          'status': 'woken_by_other',
          'wakeTime': Timestamp.fromDate(wakeTime),
          'isCompleted': true,
        });

    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid);
    await currentUserRef.update({
      'totalSleepTime': FieldValue.increment(
        wakeTime.difference(sleepStart).inSeconds,
      ),
      'totalSessions': FieldValue.increment(1),
      'lastSessionId': sessionDoc.id,
      'forcedWakeCount': FieldValue.increment(1),
      if (pointsRecovered > 0)
        'totalEarnedPoints': FieldValue.increment(pointsRecovered),
      if (pointsRecovered == 0)
        'totalUsedPoints': FieldValue.increment(reservedPoints),
      'point': FieldValue.increment(pointsRecovered),
    });

    if (pointsRecovered > 0) {
      await currentUserRef.collection('point_logs').add({
        'delta': pointsRecovered,
        'reason': '수면 목표 달성 포인트 복구',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    if (pointsToReward > 0) {
      final targetRef = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid);
      await targetRef.update({
        'point': FieldValue.increment(pointsToReward),
        'totalEarnedPoints': FieldValue.increment(pointsToReward),
        'wakeByOtherCount': FieldValue.increment(1),
        'lastWakeTime': Timestamp.fromDate(wakeTime),
      });

      await targetRef.collection('point_logs').add({
        'delta': pointsToReward,
        'reason': '타인 기상 유도 포인트 보상',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    final roomSnap =
        await FirebaseFirestore.instance
            .collection('reading_rooms')
            .doc(roomDocId)
            .get();
    final roomData = roomSnap.data();
    final roomName = roomData?['name'] ?? roomDocId;
    final seatName = '$roomName - $seatId번';
    final targetSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .get();
    final wakerNickname = targetSnapshot.data()?['nickname'] ?? '상대방';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => WakeResultScreen(
              seatName: seatName,
              resultType: '타인에 의해 기상',
              wakerNickname: wakerNickname,
              sleepStart: sleepStart,
              wakeTime: wakeTime,
              sleepDuration: sleepDuration,
              pointsEarned: pointsRecovered, // ✅ 내가 복구한 포인트로 수정
              actualSleepMinutes: actualSleepMinutes,
              overSleepMinutes: overSleepMinutes,
            ),
      ),
    );
  }

  Future<void> _handleWakeBySelf(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String currentUid = user.uid;
    final String seatIdFromQr = data['seatId'] ?? '';
    final String roomDocIdFromQr = data['roomDocId'] ?? '';

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
      sleepDuration = seatData['sleepDuration'] as int;

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
      sleepDuration = seatData['sleepDuration'] as int;

      final roomSnap =
          await FirebaseFirestore.instance
              .collection('reading_rooms')
              .doc(roomDocId)
              .get();
      final roomData = roomSnap.data();
      final readingRoomName = roomData?['name'] ?? '알 수 없는 열람실';
      seatName = '$readingRoomName - $seatId번';
    }

    final int actualSleepMinutes = wakeTime.difference(sleepStart).inMinutes;
    final int targetSleepMinutes = sleepDuration ~/ 60;
    final int overSleepMinutes = actualSleepMinutes - targetSleepMinutes;
    final int reservedPoints =
        sleepDuration <= 1800 ? 10 : (sleepDuration - 1800);

    int pointsDelta = 0;
    if (overSleepMinutes >= 30) {
      pointsDelta = 0;
    } else if (overSleepMinutes >= 10) {
      pointsDelta = 5;
    } else {
      pointsDelta = reservedPoints;
    }

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
      'result': 'wake_by_self',
      'pointsGiven': pointsDelta,
      'seatId': seatId,
      'roomDocId': roomDocId,
    });

    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid);
    await currentUserRef.update({
      'totalSleepTime': FieldValue.increment(
        wakeTime.difference(sleepStart).inSeconds,
      ),
      'totalSessions': FieldValue.increment(1),
      'selfWakeCount': FieldValue.increment(1),
      'lastSessionId': sessionRef.id,
      'lastWakeTime': Timestamp.fromDate(wakeTime),
      if (pointsDelta > 0)
        'totalEarnedPoints': FieldValue.increment(pointsDelta),
      if (pointsDelta < 0)
        'totalUsedPoints': FieldValue.increment(pointsDelta.abs()),
      'point': FieldValue.increment(pointsDelta),
    });

    final logRef = currentUserRef.collection('point_logs').doc();
    await logRef.set({
      'logId': logRef.id,
      'delta': pointsDelta,
      'reason': pointsDelta > 0 ? '수면 목표 달성 포인트 복구' : '수면 목표 초과 벌점',
      'timestamp': FieldValue.serverTimestamp(),
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => WakeResultScreen(
              seatName: seatName,
              resultType: '스스로 기상',
              wakerNickname: '본인',
              sleepStart: sleepStart,
              wakeTime: wakeTime,
              sleepDuration: sleepDuration,
              pointsEarned: pointsDelta,
              actualSleepMinutes: actualSleepMinutes,
              overSleepMinutes: overSleepMinutes,
            ),
      ),
    );
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

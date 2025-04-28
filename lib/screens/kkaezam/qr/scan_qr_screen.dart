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

      // ✅ 고정 QR (seatId, roomDocId가 비어있을 때) 처리
      if (seatIdFromQr.isEmpty || roomDocIdFromQr.isEmpty) {
        final uid = user.uid;

        // 1. 현재 사용자의 예약 좌석 찾기
        final seatSnapshot =
            await FirebaseFirestore.instance
                .collectionGroup('seats')
                .where('reservedBy', isEqualTo: uid)
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
        final seatId = seatData['seatId'] ?? '';
        final roomDocId = seatDoc.reference.parent.parent?.id ?? '';

        final sleepStart = (seatData['sleepStart'] as Timestamp?)?.toDate();
        final int sleepDuration = seatData['sleepDuration'] ?? 0;
        final wakeTime = DateTime.now();

        if (sleepStart == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('수면 시작 시간이 없습니다.')));
          return;
        }

        // 2. 열람실 이름 가져오기
        final roomSnap =
            await FirebaseFirestore.instance
                .collection('reading_rooms')
                .doc(roomDocId)
                .get();
        final roomData = roomSnap.data();
        final readingRoomName = roomData?['name'] ?? '알 수 없는 열람실';
        final seatName = '$readingRoomName - $seatId번';

        // ✅ WakeResultScreen 이동
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
                  pointsEarned: 0,
                ),
          ),
        );
        controller.stop();
        return;
      }

      // ✅ 일반 QR (seatId, roomDocId 포함된 경우)
      final seatRef = FirebaseFirestore.instance
          .collection('reading_rooms')
          .doc(roomDocIdFromQr)
          .collection('seats')
          .doc(seatIdFromQr);

      final seatSnap = await seatRef.get();
      final seatData = seatSnap.data();

      if (seatData == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('좌석 정보를 찾을 수 없습니다.')));
        return;
      }

      final sleepStart = (seatData['sleepStart'] as Timestamp?)?.toDate();
      final wakeTime = (seatData['wakeTime'] as Timestamp?)?.toDate();
      final int sleepDuration = seatData['sleepDuration'] ?? 0;

      if (sleepStart == null || wakeTime == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('수면 시작 또는 기상 시간이 없습니다.')));
        return;
      }

      // 🔥 열람실 이름 읽기
      final roomSnap =
          await FirebaseFirestore.instance
              .collection('reading_rooms')
              .doc(roomDocIdFromQr)
              .get();
      final roomData = roomSnap.data();
      final readingRoomName = roomData?['name'] ?? '알 수 없는 열람실';

      // 🔥 seatName 조합
      final seatName = '$readingRoomName - $seatIdFromQr번';

      // 🔥 기상 결과 타입 구분
      String resultType = '기타';
      if (type == 'wake_by_self') {
        resultType = '스스로 기상';
      } else if (type == 'wake_by_other') {
        resultType = '타인에 의해 기상';
      }

      // 🔥 깨워준 사람 닉네임 가져오기
      String wakerNickname = '본인';
      if (type == 'wake_by_other' && scannedUid != currentUid) {
        final wakerSnap =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUid)
                .get();
        wakerNickname = wakerSnap.data()?['nickname'] ?? '알 수 없음';
      }

      // 🔥 포인트 계산 (수면 시간 기반, 1분 = 1포인트 가정)
      int points = wakeTime.difference(sleepStart).inMinutes;

      // ✅ 결과 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => WakeResultScreen(
                seatName: seatName,
                resultType: resultType,
                wakerNickname: wakerNickname,
                sleepStart: sleepStart,
                wakeTime: wakeTime,
                sleepDuration: sleepDuration,
                pointsEarned: points,
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

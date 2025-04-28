// lib/screens/kkaezam/qr/generate_self_wake_qr_screen.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../utils/qr_helper.dart';

class GenerateSelfWakeQrScreen extends StatelessWidget {
  const GenerateSelfWakeQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✏️ 고정 QR 데이터 구성
    final data = {
      'type': 'wake_by_self',
      'uid': 'universal_self_wake', // ✅ 일반적인 "모든 유저용" 스캔 가능하게
      'seatId': '', // 좌석 정보 없음
      'roomDocId': '', // 열람실 정보 없음
    };

    final qrString = QrHelper.encodeQrData(data);

    return Scaffold(
      appBar: AppBar(
        title: const Text('고정 스스로 기상 QR 생성'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Center(
        child: QrImageView(
          data: qrString,
          version: QrVersions.auto,
          size: 300.0,
        ),
      ),
    );
  }
}

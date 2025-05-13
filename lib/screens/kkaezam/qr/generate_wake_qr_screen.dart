// lib/screens/kkaezam/qr/generate_wake_qr_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../utils/qr_helper.dart';

class GenerateWakeQrScreen extends StatelessWidget {
  final String seatId;
  final String roomDocId;
  final String targetUid; // 👈 깨울 대상 UID

  const GenerateWakeQrScreen({
    super.key,
    required this.seatId,
    required this.roomDocId,
    required this.targetUid,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }

    final data = {
      'type': 'wake_by_other',
      'seatId': seatId,
      'roomDocId': roomDocId,
      'wakerUid': user.uid, // 깨우는 사람
      'targetUid': targetUid, // 깨울 대상자
      'generatedAt': DateTime.now().toIso8601String(),
    };

    final qrString = QrHelper.encodeQrData(data);

    return Scaffold(
      appBar: AppBar(title: const Text('기상 유도 QR 생성')),
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

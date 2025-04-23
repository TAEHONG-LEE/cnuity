// lib/screens/admin/mission_initializer_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class MissionInitializerScreen extends StatelessWidget {
  const MissionInitializerScreen({super.key});

  Future<void> _uploadMissionsFromAsset(BuildContext context) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/kkaezam_missions.json',
      );
      final Map<String, dynamic> missions = json.decode(jsonString);

      final batch = FirebaseFirestore.instance.batch();
      final missionRef = FirebaseFirestore.instance.collection('missions');

      missions.forEach((id, data) {
        batch.set(missionRef.doc(id), data);
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('미션 초기화 완료!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('미션 초기화'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: const Text('미션 JSON 업로드'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          onPressed: () => _uploadMissionsFromAsset(context),
        ),
      ),
    );
  }
}

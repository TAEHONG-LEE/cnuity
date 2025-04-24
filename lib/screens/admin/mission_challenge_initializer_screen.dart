// lib/screens/admin/mission_challenge_initializer_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MissionChallengeInitializerScreen extends StatelessWidget {
  const MissionChallengeInitializerScreen({super.key});

  Future<void> _initializeChallengingMissions(BuildContext context) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final missionSnapshot =
          await FirebaseFirestore.instance
              .collection('missions')
              .where('active', isEqualTo: true)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      final challengeRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('challenging_missions');

      for (final doc in missionSnapshot.docs) {
        batch.set(challengeRef.doc(doc.id), {'startedAt': Timestamp.now()});
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('도전 미션 초기화 완료')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도전 미션 초기화'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.flag_circle),
          label: const Text('미션 도전상태 일괄 생성'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
          onPressed: () => _initializeChallengingMissions(context),
        ),
      ),
    );
  }
}

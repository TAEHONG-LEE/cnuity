// lib/screens/kkaezam/kkaezam_mission_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class KkaezamMissionScreen extends StatelessWidget {
  const KkaezamMissionScreen({super.key});

  Future<void> _startMission(String missionId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final challengeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('challenging_missions')
        .doc(missionId);

    await challengeRef.set({'startedAt': Timestamp.now()});
  }

  Future<void> _claimMissionReward(
    BuildContext context,
    String missionId,
    int reward,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final missionClaimRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('claimed_missions')
        .doc(missionId);

    final missionClaimSnap = await missionClaimRef.get();
    if (missionClaimSnap.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 보상을 받은 미션입니다.')));
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(missionClaimRef, {'claimedAt': Timestamp.now()});
      transaction.update(userRef, {
        'point': FieldValue.increment(reward),
        'totalEarnedPoints': FieldValue.increment(reward),
      });
    });

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('미션 보상 ${reward}P 획득!')));
    }
  }

  Future<bool> _isMissionChallenged(String missionId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('challenging_missions')
            .doc(missionId)
            .get();

    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('미션 목록'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('missions')
                .where('active', isEqualTo: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('미션을 불러오는 데 실패했습니다.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final missions = snapshot.data!.docs;

          if (missions.isEmpty) {
            return const Center(child: Text('현재 사용 가능한 미션이 없습니다.'));
          }

          return ListView.builder(
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final mission = missions[index].data() as Map<String, dynamic>;
              final missionId = snapshot.data!.docs[index].id;
              final reward = mission['reward'] ?? 0;

              return FutureBuilder<bool>(
                future: _isMissionChallenged(missionId),
                builder: (context, snapshot) {
                  final isChallenged = snapshot.data ?? false;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: Colors.orange[700],
                            size: 36,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mission['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  mission['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              Text(
                                '+${reward}P',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 6),
                              isChallenged
                                  ? ElevatedButton(
                                    onPressed:
                                        () => _claimMissionReward(
                                          context,
                                          missionId,
                                          reward,
                                        ),
                                    child: const Text('보상받기'),
                                  )
                                  : ElevatedButton(
                                    onPressed: () => _startMission(missionId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                    ),
                                    child: const Text('도전하기'),
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

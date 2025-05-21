// lib/screens/kkaezam/kkaezam_mission_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KkaezamMissionScreen extends StatefulWidget {
  const KkaezamMissionScreen({super.key});

  @override
  State<KkaezamMissionScreen> createState() => _KkaezamMissionScreenState();
}

class _KkaezamMissionScreenState extends State<KkaezamMissionScreen> {
  Set<String> challengedMissionIds = {};
  Set<String> claimedMissionIds = {};
  Map<String, dynamic> userStats = {};

  Future<void> _loadChallengedMissions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('challenging_missions')
            .get();

    setState(() {
      challengedMissionIds = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> _loadClaimedMissions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('claimed_missions')
            .get();

    setState(() {
      claimedMissionIds = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> _loadUserStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    setState(() {
      userStats = doc.data() ?? {};
    });
  }

  Future<void> _startMission(String missionId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final challengeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('challenging_missions')
        .doc(missionId);

    final alreadyExists = await challengeRef.get();
    if (!alreadyExists.exists) {
      await challengeRef.set({'startedAt': Timestamp.now()});
    }
    await _loadChallengedMissions();
  }

  Future<void> _claimMissionReward(
    BuildContext context,
    String missionId,
    String missionTitle,
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
    final rewardLogRef = userRef.collection('mission_rewards').doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(missionClaimRef, {'claimedAt': Timestamp.now()});
      transaction.set(rewardLogRef, {
        'missionId': missionId,
        'title': missionTitle,
        'reward': reward,
        'claimedAt': Timestamp.now(),
      });
      transaction.update(userRef, {
        'point': FieldValue.increment(reward),
        'totalEarnedPoints': FieldValue.increment(reward),
      });
    });

    await _loadClaimedMissions();

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('미션 보상 ${reward}P 획득!')));
    }
  }

  bool _isMissionClearable(String type, int targetCount) {
    final selfWake = userStats['selfWakeCount'] ?? 0;
    final forcedWake = userStats['forcedWakeCount'] ?? 0;
    final appOpenStreak = userStats['appOpenStreak'] ?? 0;
    final lastWakeTime =
        userStats['lastWakeTime'] != null
            ? (userStats['lastWakeTime'] as Timestamp).toDate()
            : null;

    switch (type) {
      case 'self_wake_streak':
        return selfWake >= targetCount;
      case 'wake_by_other_count':
        return forcedWake >= targetCount;
      case 'app_open_streak':
        return appOpenStreak >= targetCount;
      case 'wake_before_time':
        if (lastWakeTime == null) return false;
        final limit = TimeOfDay(hour: 7, minute: 0);
        return TimeOfDay.fromDateTime(lastWakeTime).hour < limit.hour ||
            (TimeOfDay.fromDateTime(lastWakeTime).hour == limit.hour &&
                TimeOfDay.fromDateTime(lastWakeTime).minute <= limit.minute);
      case 'seat_return':
        return userStats['lastSeatReturn'] != null;
      case 'custom_goal_timer':
        return userStats['goalCertified'] == true;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadChallengedMissions();
    _loadClaimedMissions();
    _loadUserStats();
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
              final type = mission['type'] ?? 'self_wake_streak';
              final target = mission['targetCount'] ?? 1;
              final isChallenged = challengedMissionIds.contains(missionId);
              final isClearable = _isMissionClearable(type, target);
              final isClaimed = claimedMissionIds.contains(missionId);
              final title = mission['title'] ?? '';

              if (isClearable && !isChallenged) {
                _startMission(missionId);
              }

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
                              title,
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
                          if (isClaimed)
                            const Text(
                              '보상 완료',
                              style: TextStyle(color: Colors.grey),
                            )
                          else if (isChallenged && isClearable)
                            ElevatedButton(
                              onPressed:
                                  () => _claimMissionReward(
                                    context,
                                    missionId,
                                    title,
                                    reward,
                                  ),
                              child: const Text('보상받기'),
                            )
                          else if (!isChallenged)
                            ElevatedButton(
                              onPressed: () => _startMission(missionId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF5197FF),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('도전하기'),
                            )
                          else
                            ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                              ),
                              child: const Text('진행 중'),
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
      ),
    );
  }
}

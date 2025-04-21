import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class KkaezamHistoryScreen extends StatefulWidget {
  const KkaezamHistoryScreen({super.key});

  @override
  State<KkaezamHistoryScreen> createState() => _KkaezamHistoryScreenState();
}

class _KkaezamHistoryScreenState extends State<KkaezamHistoryScreen> {
  late Future<Map<String, dynamic>> userInfo;
  late Future<List<Map<String, dynamic>>> sessionHistory;

  @override
  void initState() {
    super.initState();
    userInfo = _fetchUserInfo();
    sessionHistory = _fetchSessionHistory();
  }

  Future<Map<String, dynamic>> _fetchUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data() ?? {};
  }

  Future<List<Map<String, dynamic>>> _fetchSessionHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sleep_sessions')
            .orderBy('startTime', descending: true)
            .limit(5)
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}분 ${s}초';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 기록'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: FutureBuilder(
        future: Future.wait([userInfo, sessionHistory]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data![0] as Map<String, dynamic>;
          final sessions = snapshot.data![1] as List<Map<String, dynamic>>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '닉네임: ${user['nickname'] ?? '알 수 없음'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text('보유 포인트: ${user['point'] ?? 0}P'),
                  const SizedBox(height: 12),
                  Text(
                    '총 수면 시간: ${formatDuration(user['totalSleepTime'] ?? 0)}',
                  ),
                  Text('총 세션 수: ${user['totalSessions'] ?? 0}회'),
                  Text('스스로 기상: ${user['selfWakeCount'] ?? 0}회'),
                  Text('타인 기상: ${user['forcedWakeCount'] ?? 0}회'),
                  Text('총 획득 포인트: ${user['totalEarnedPoints'] ?? 0}P'),
                  Text('총 사용 포인트: ${user['totalUsedPoints'] ?? 0}P'),
                  const Divider(height: 32),
                  const Text(
                    '최근 수면 이력',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...sessions.map((s) {
                    final time = (s['startTime'] as Timestamp?)?.toDate();
                    final end = (s['endTime'] as Timestamp?)?.toDate();
                    return ListTile(
                      title: Text(
                        '${time?.toLocal().toString().split(" ")[0]}  -  ${s['result']}',
                      ),
                      subtitle: Text(
                        '예정 ${formatDuration(s['sleepDuration'])}, 실제 ${end != null && time != null ? formatDuration(end.difference(time).inSeconds) : '측정불가'}',
                      ),
                      trailing: Text('+${s['pointsGiven'] ?? 0}P'),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

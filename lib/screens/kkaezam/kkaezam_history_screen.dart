// lib/screens/kkaezam/kkaezam_history_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/kkaezam/user_stats_section.dart';
import '../../widgets/kkaezam/point_summary_section.dart';
import '../../widgets/kkaezam/point_log_list_section.dart';
import '../../widgets/kkaezam/sleep_session_history_section.dart';

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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserStatsSection(user: user),
                const SizedBox(height: 24),
                PointSummarySection(user: user),
                const SizedBox(height: 24),
                PointLogListSection(uid: uid),
                const SizedBox(height: 24),
                SleepSessionHistorySection(sessions: sessions),
              ],
            ),
          );
        },
      ),
    );
  }
}

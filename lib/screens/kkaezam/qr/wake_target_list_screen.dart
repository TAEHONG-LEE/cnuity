// lib/screens/kkaezam/qr/wake_target_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'generate_wake_qr_screen.dart'; // 🔄 디렉토리 구조 반영

class WakeTargetListScreen extends StatefulWidget {
  const WakeTargetListScreen({super.key});

  @override
  State<WakeTargetListScreen> createState() => _WakeTargetListScreenState();
}

class _WakeTargetListScreenState extends State<WakeTargetListScreen> {
  List<Map<String, dynamic>> sleepySeats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSleepingSeats();
  }

  // 🔍 상태가 sleeping인 좌석 중, 수면 시간이 초과된 좌석만 필터링
  Future<void> fetchSleepingSeats() async {
    final now = DateTime.now();
    final querySnapshot =
        await FirebaseFirestore.instance
            .collectionGroup('seats')
            .where('status', isEqualTo: 'sleeping')
            .get();

    final results = <Map<String, dynamic>>[];

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final Timestamp start = data['sleepStart'];
      final int duration = data['sleepDuration'];
      final seatId = data['seatId'];
      final roomDocId = data['roomDocId'];

      final DateTime startTime = start.toDate();
      final int elapsed = now.difference(startTime).inSeconds;

      if (elapsed > duration) {
        final overtime = elapsed - duration;
        results.add({
          'seatId': seatId,
          'roomDocId': roomDocId,
          'overtime': overtime,
        });
      }
    }

    // 🔽 초과 시간이 긴 순서로 정렬
    results.sort((a, b) => b['overtime'].compareTo(a['overtime']));

    setState(() {
      sleepySeats = results;
      isLoading = false;
    });
  }

  String formatOvertime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '+${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기상 대상자 목록'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: sleepySeats.length,
                itemBuilder: (context, index) {
                  final seat = sleepySeats[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.event_seat),
                      title: Text('${seat['seatId']}번 좌석'),
                      subtitle: Text(
                        '초과 시간: ${formatOvertime(seat['overtime'])}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      // 👉 좌석 클릭 시 QR 생성 화면으로 이동
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => GenerateWakeQrScreen(
                                  seatId: seat['seatId'],
                                  roomDocId: seat['roomDocId'],
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}

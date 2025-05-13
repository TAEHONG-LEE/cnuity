// lib/screens/kkaezam/qr/wake_target_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'generate_wake_qr_screen.dart';

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

  // sleeping 상태이면서 수면 시간이 초과된 좌석만 필터링
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
      final Timestamp? start = data['sleepStart'];
      final int? duration = data['sleepDuration'];
      final String? seatId = data['seatId'];
      final String? roomDocId = data['roomDocId'];
      final String? reservedBy = data['reservedBy']; // ✅ 추가됨

      if (start == null ||
          duration == null ||
          seatId == null ||
          roomDocId == null ||
          reservedBy == null) {
        continue;
      }

      final DateTime startTime = start.toDate();
      final int elapsed = now.difference(startTime).inSeconds;

      if (elapsed > duration) {
        final overtime = elapsed - duration;
        results.add({
          'seatId': seatId,
          'roomDocId': roomDocId,
          'targetUid': reservedBy, // ✅ QR로 전달될 대상 UID
          'overtime': overtime,
        });
      }
    }

    // 초과 시간 기준 정렬
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => GenerateWakeQrScreen(
                                  seatId: seat['seatId'],
                                  roomDocId: seat['roomDocId'],
                                  targetUid: seat['targetUid'], // ✅ target 전달
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

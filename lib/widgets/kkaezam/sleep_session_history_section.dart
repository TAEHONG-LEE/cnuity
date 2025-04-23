// lib/widgets/kkaezam/sleep_session_history_section.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SleepSessionHistorySection extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;

  const SleepSessionHistorySection({super.key, required this.sessions});

  String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}분 ${s}초';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🛌 최근 수면 이력',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...sessions.map((s) {
          final time = (s['startTime'] as Timestamp?)?.toDate();
          final end = (s['endTime'] as Timestamp?)?.toDate();
          final int givenPoints = s['pointsGiven'] ?? 0;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(
                '${time?.toLocal().toString().split(" ")[0]} - ${s['result'] ?? '결과 없음'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('예정 ${formatDuration(s['sleepDuration'])}'),
                  Text(
                    end != null && time != null
                        ? '실제 ${formatDuration(end.difference(time).inSeconds)}'
                        : '실제 시간 측정불가',
                  ),
                ],
              ),
              trailing: Text(
                '+${givenPoints}P',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: givenPoints > 0 ? Colors.green : Colors.grey,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

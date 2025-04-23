// lib/widgets/kkaezam/user_stats_section.dart

import 'package:flutter/material.dart';

class UserStatsSection extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserStatsSection({super.key, required this.user});

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}시간 ${minutes}분';
  }

  @override
  Widget build(BuildContext context) {
    final totalSessions = user['totalSessions'] ?? 0;
    final selfWake = user['selfWakeCount'] ?? 0;
    final forcedWake = user['forcedWakeCount'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 수면 통계',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('총 수면 시간: ${_formatDuration(user['totalSleepTime'] ?? 0)}'),
            Text('총 세션 수: $totalSessions 회'),
            Row(
              children: [
                const Text('스스로 기상: '),
                Expanded(
                  child: LinearProgressIndicator(
                    value: totalSessions > 0 ? selfWake / totalSessions : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$selfWake 회'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('타인 기상: '),
                Expanded(
                  child: LinearProgressIndicator(
                    value: totalSessions > 0 ? forcedWake / totalSessions : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$forcedWake 회'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

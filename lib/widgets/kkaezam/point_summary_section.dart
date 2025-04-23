// lib/widgets/kkaezam/point_summary_section.dart

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class PointSummarySection extends StatelessWidget {
  final Map<String, dynamic> user;

  const PointSummarySection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final int earned = user['totalEarnedPoints'] ?? 0;
    final int used = user['totalUsedPoints'] ?? 0;
    final int current = user['point'] ?? 0;
    final int total = earned + used > 0 ? earned + used : 1;

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
              '💰 포인트 요약',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '현재 포인트: $current P',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearPercentIndicator(
              lineHeight: 12,
              percent: earned / total,
              backgroundColor: Colors.grey.shade300,
              progressColor: Colors.green,
              barRadius: const Radius.circular(16),
              animation: true,
              animationDuration: 600,
              trailing: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '획득률 ${(earned / total * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('획득: $earned P'),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.arrow_downward, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('사용: $used P'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

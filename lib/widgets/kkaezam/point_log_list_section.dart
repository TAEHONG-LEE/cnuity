// lib/widgets/kkaezam/point_log_list_section.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PointLogListSection extends StatelessWidget {
  final String uid;

  const PointLogListSection({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 포인트 로그',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('point_logs')
                  .orderBy('timestamp', descending: true)
                  .limit(10)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('포인트 로그를 불러오는 중 오류가 발생했습니다.');
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final logs = snapshot.data!.docs;

            if (logs.isEmpty) {
              return SizedBox(
                width: double.infinity,
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          '포인트 로그가 없습니다.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: logs.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final log = logs[index].data() as Map<String, dynamic>;
                final int delta = log['delta'] ?? 0;
                final String reason = log['reason'] ?? '';
                final Timestamp? timestamp = log['timestamp'];
                final String timeStr =
                    timestamp != null
                        ? timestamp.toDate().toLocal().toString().split('.')[0]
                        : '';

                return Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      delta >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: delta >= 0 ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      '${delta >= 0 ? '+' : ''}$delta P',
                      style: TextStyle(
                        color: delta >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reason),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

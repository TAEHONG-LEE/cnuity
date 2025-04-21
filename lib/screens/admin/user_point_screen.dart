// lib/screens/admin/user_point_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserPointScreen extends StatefulWidget {
  const UserPointScreen({super.key});

  @override
  State<UserPointScreen> createState() => _UserPointScreenState();
}

class _UserPointScreenState extends State<UserPointScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updatePoint(String uid, int newPoint) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'point': newPoint,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('포인트가 업데이트되었습니다.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('업데이트 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('유저 포인트 관리'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('데이터를 불러오는 데 실패했습니다.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final uid = doc.id;
              final data = doc.data() as Map<String, dynamic>;
              final email = data['email'] ?? '알 수 없음';
              final point = data['point'] ?? 0;

              _controllers.putIfAbsent(
                uid,
                () => TextEditingController(text: point.toString()),
              );

              return ListTile(
                title: Text(email),
                subtitle: Text('UID: ${uid.substring(0, 6)}...'),
                trailing: SizedBox(
                  width: 160,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controllers[uid],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final newPoint = int.tryParse(
                            _controllers[uid]!.text,
                          );
                          if (newPoint != null && newPoint >= 0) {
                            _updatePoint(uid, newPoint);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('유효한 포인트를 입력해주세요.')),
                            );
                          }
                        },
                        child: const Text('저장'),
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

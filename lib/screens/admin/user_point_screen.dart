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

  Future<void> _updatePoint(String uid, String nickname) async {
    final controller = _controllers[uid];
    if (controller == null) return;

    final int? newPoint = int.tryParse(controller.text.trim());
    if (newPoint == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'point': newPoint,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nickname 포인트가 $newPoint로 업데이트되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 포인트 관리'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final users = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final user = users[index];
              final uid = user.id;
              final nickname = user['nickname'] ?? '이름 없음';
              final email = user['email'] ?? '';
              final int point = user['point'] ?? 0;

              _controllers.putIfAbsent(
                uid,
                () => TextEditingController(text: point.toString()),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$nickname ($email)',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controllers[uid],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '포인트'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _updatePoint(uid, nickname),
                        child: const Text('저장'),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

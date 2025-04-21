import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserInitializerScreen extends StatelessWidget {
  const UserInitializerScreen({super.key});

  Future<void> _initializeUsers(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    // 임시로 초기화할 유저 리스트
    final usersToCreate = [
      {'uid': 'user1', 'email': 'user1@example.com', 'nickname': '유저1'},
      {'uid': 'user2', 'email': 'user2@example.com', 'nickname': '유저2'},
      {'uid': 'user3', 'email': 'user3@example.com', 'nickname': '유저3'},
    ];

    for (final user in usersToCreate) {
      final userRef = firestore.collection('users').doc(user['uid']);

      await userRef.set({
        'uid': user['uid'],
        'email': user['email'],
        'nickname': user['nickname'],
        'point': 50, // 초기 포인트
        'totalSleepTime': 0, // 총 수면 시간 (초)
        'totalSessions': 0, // 총 세션 수
        'selfWakeCount': 0, // 스스로 기상한 횟수
        'forcedWakeCount': 0, // 타인에 의해 기상된 횟수
        'lastSessionId': '', // 마지막 세션 ID
        'createdAt': FieldValue.serverTimestamp(),
        'isAdmin': false, // 관리자 여부
      }, SetOptions(merge: true));
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('유저 정보가 초기화되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('유저 포인트 초기화'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _initializeUsers(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: const Text(
            '유저 컬렉션 생성 및 초기화',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

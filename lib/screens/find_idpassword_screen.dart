// lib/screens/find_idpassword_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FindIdPasswordScreen extends StatefulWidget {
  const FindIdPasswordScreen({super.key});

  @override
  State<FindIdPasswordScreen> createState() => _FindIdPasswordScreenState();
}

class _FindIdPasswordScreenState extends State<FindIdPasswordScreen> {
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // 아이디 찾기 (닉네임 기반 이메일 검색)
  Future<void> findEmailByNickname() async {
    String nickname = nicknameController.text.trim();

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('nickname', isEqualTo: nickname)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final email = snapshot.docs.first['email'];
        Fluttertoast.showToast(msg: '이메일: $email');
      } else {
        Fluttertoast.showToast(msg: '해당 닉네임을 찾을 수 없습니다.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '오류: ${e.toString()}');
    }
  }

  // 비밀번호 재설정
  Future<void> sendPasswordResetEmail() async {
    String email = emailController.text.trim();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(msg: '재설정 메일이 전송되었습니다.');
    } catch (e) {
      Fluttertoast.showToast(msg: '오류: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('아이디/비밀번호 찾기'),
          bottom: const TabBar(
            tabs: [Tab(text: '아이디 찾기'), Tab(text: '비밀번호 재설정')],
          ),
        ),
        body: TabBarView(
          children: [
            // 아이디 찾기
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("닉네임을 입력하면 가입된 이메일을 알려드립니다."),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nicknameController,
                    decoration: const InputDecoration(
                      labelText: '닉네임',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: findEmailByNickname,
                    child: const Text('이메일 찾기'),
                  ),
                ],
              ),
            ),

            // 비밀번호 재설정
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("가입한 이메일을 입력하면 재설정 메일을 보냅니다."),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: sendPasswordResetEmail,
                    child: const Text('재설정 메일 보내기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

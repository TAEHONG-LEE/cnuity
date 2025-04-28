// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();

  bool _isProcessing = false;

  Future<void> navigateToLoginScreen(BuildContext context) async {
    if (!context.mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<bool> register() async {
    if (_isProcessing) return false;
    setState(() => _isProcessing = true);

    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String nickname = nicknameController.text.trim();

    if (password.length < 6) {
      Fluttertoast.showToast(msg: "비밀번호는 최소 6자 이상이어야 합니다.");
      setState(() => _isProcessing = false);
      return false;
    }

    if (nickname.isEmpty) {
      Fluttertoast.showToast(msg: "닉네임을 입력해주세요.");
      setState(() => _isProcessing = false);
      return false;
    }

    try {
      // 닉네임 중복 체크
      final nicknameSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('nickname', isEqualTo: nickname)
              .limit(1)
              .get();

      if (nicknameSnapshot.docs.isNotEmpty) {
        Fluttertoast.showToast(msg: "이미 사용 중인 닉네임입니다.");
        setState(() => _isProcessing = false);
        return false;
      }

      // 이메일로 회원가입 시도
      final UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = credential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        await userDoc.set({
          'uid': user.uid,
          'email': email,
          'nickname': nickname,
          'point': 50,
          'totalSleepTime': 0,
          'totalSessions': 0,
          'selfWakeCount': 0,
          'forcedWakeCount': 0,
          'lastSessionId': '',
          'createdAt': FieldValue.serverTimestamp(),
          'isAdmin': false,
          'totalEarnedPoints': 0,
          'totalUsedPoints': 0,
        });

        Fluttertoast.showToast(msg: "회원가입 성공");
        await navigateToLoginScreen(context);
        return true;
      } else {
        Fluttertoast.showToast(msg: "회원가입에 실패했습니다. 다시 시도해주세요.");
        return false;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Fluttertoast.showToast(msg: "이미 사용 중인 이메일입니다.");
      } else {
        Fluttertoast.showToast(msg: "에러 발생: ${e.message}");
      }
      return false;
    } catch (e) {
      Fluttertoast.showToast(msg: "알 수 없는 에러: $e");
      return false;
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: SingleChildScrollView(
        // 🔥 여기 추가
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '회원가입',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: '이메일을 입력하세요'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호를 입력하세요'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(labelText: '닉네임을 입력하세요'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : register,
              child:
                  _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        '회원가입',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5197FF),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 24,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('이미 계정이 있나요? 로그인'),
            ),
          ],
        ),
      ),
    );
  }
}

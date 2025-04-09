import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'signup_screen.dart'; // 회원가입 화면으로 이동

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Fluttertoast.showToast(msg: "로그인 성공");
      // TODO: 로그인 성공 후 홈 화면 이동 구현
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Fluttertoast.showToast(msg: "사용자를 찾을 수 없습니다.");
      } else if (e.code == 'wrong-password') {
        Fluttertoast.showToast(msg: "잘못된 비밀번호입니다.");
      } else {
        Fluttertoast.showToast(msg: "로그인 에러: ${e.message}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('CNUITY 로그인'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'CNUITY 로그인',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '이메일을 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호를 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text('이메일로 로그인'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5197FF),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 24,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Fluttertoast.showToast(msg: "비밀번호 찾기 화면으로 이동");
              },
              child: const Text('비밀번호 찾기'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text('회원가입'),
            ),
            const SizedBox(height: 20),
            const Text('간편 로그인'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.email),
                  onPressed: () {
                    Fluttertoast.showToast(msg: "구글 로그인");
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.apple),
                  onPressed: () {
                    Fluttertoast.showToast(msg: "애플 로그인");
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

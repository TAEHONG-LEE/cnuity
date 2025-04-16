import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'signup_screen.dart';
import 'home/home_screen.dart';
import 'admin/seat_initializer_screen.dart'; // 관리자용 화면 import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> navigateToHome(BuildContext context) async {
    if (!context.mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Fluttertoast.showToast(msg: "로그인 성공");
      await navigateToHome(context);
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

  Future<void> adminAutoLogin() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'admin@cnuity.com',
        password: 'adminpassword123',
      );

      if (!context.mounted) return;

      // ✅ 필요 시 아래 줄 주석 해제하여 관리자 페이지로 진입
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (_) => const SeatInitializerScreen()),
      // );

      // ✅ 기본 흐름: 일반 사용자처럼 홈으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: "자동 로그인 실패: ${e.message}");
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
              child: const Text(
                '이메일로 로그인',
                style: TextStyle(
                  color: Colors.white,
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
            ElevatedButton(
              onPressed: adminAutoLogin,
              child: const Text(
                '자동 로그인',
                style: TextStyle(
                  color: Colors.white,
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

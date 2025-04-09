import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'login_screen.dart'; // 로그인 화면으로 이동

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isProcessing = false;

  // 회원가입
  Future<void> register() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (password.length < 6) {
      Fluttertoast.showToast(msg: "비밀번호는 최소 6자 이상이어야 합니다.");
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = credential.user;

      if (user != null) {
        Fluttertoast.showToast(msg: "회원가입 성공");

        if (context.mounted) {
          // 🔥 context가 유효한 상태에서 이동
          Future.microtask(() {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          });
        }
      } else {
        Fluttertoast.showToast(msg: "회원가입에 실패했습니다. 다시 시도해주세요.");
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: "에러 발생: ${e.message}");
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
      body: Padding(
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : register,
              child:
                  _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('회원가입'),
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

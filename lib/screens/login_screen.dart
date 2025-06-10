import 'package:cnuity/screens/admin/admin_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'signup_screen.dart';
import 'home/home_screen.dart';
import 'find_idpassword_screen.dart';
import 'admin/seat_initializer_screen.dart'; // 관리자용 화면 import
import '../utils/fcm_helper.dart'; // FCM 관련 import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;

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

    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "이메일과 비밀번호를 모두 입력해주세요.");
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      Fluttertoast.showToast(msg: "올바른 이메일 형식을 입력해주세요.");
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Fluttertoast.showToast(msg: "로그인 성공");
      await FcmService.init();
      await navigateToHome(context);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "등록되지 않은 이메일입니다.";
          break;
        case 'wrong-password':
          message = "비밀번호가 일치하지 않습니다. 다시 입력해주세요.";
          break;
        case 'invalid-email':
          message = "올바른 이메일 형식이 아닙니다.";
          break;
        case 'invalid-argument':
          message = "올바른 이메일 형식을 입력해주세요.";
          break;
        case 'invalid-credential':
          message = "등록되지 않았거나 비밀번호가 잘못되었습니다.";
          break;
        default:
          message = "로그인 중 오류가 발생했습니다. 다시 시도해주세요.";
      }
      Fluttertoast.showToast(msg: message);
    }
  }

  Future<void> adminAutoLogin() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'admin@cnuity.com',
        password: 'adminpassword123',
      );
      await FcmService.init();
      if (!context.mounted) return;

      // // ✅ 필요 시 아래 줄 주석 해제하여 관리자 페이지로 진입
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      // );

      // ✅ 기본 흐름: 일반 사용자처럼 홈으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = "관리자 비밀번호가 잘못되었습니다.";
          break;
        case 'user-not-found':
          message = "관리자 계정을 찾을 수 없습니다.";
          break;
        default:
          message = "자동 로그인 실패: 네트워크 또는 서버 오류입니다.";
      }
      Fluttertoast.showToast(msg: message);
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
              obscureText: _obscurePassword, // ← 변경
              decoration: InputDecoration(
                labelText: '비밀번호를 입력하세요',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
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
            // ElevatedButton(
            //   onPressed: adminAutoLogin,
            //   child: const Text(
            //     '자동 로그인',
            //     style: TextStyle(
            //       color: Colors.white,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: const Color(0xFF5197FF),
            //     padding: const EdgeInsets.symmetric(
            //       vertical: 10,
            //       horizontal: 24,
            //     ),
            //   ),
            // ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Fluttertoast.showToast(msg: "아이디/비밀번호 찾기 화면으로 이동");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FindIdPasswordScreen(),
                  ),
                );
              },
              child: const Text('아이디/비밀번호 찾기'),
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

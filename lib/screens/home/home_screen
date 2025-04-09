import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart'; // 로그인 화면
import 'screens/signup_screen.dart'; // 회원가입 화면

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CNUITY',
      theme: ThemeData(
        primaryColor: const Color(0xFF5197FF),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // 앱 시작 시 로그인 화면
    );
  }
}

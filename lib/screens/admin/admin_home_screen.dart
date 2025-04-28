import 'package:flutter/material.dart';
import 'seat_initializer_screen.dart';
import 'user_point_screen.dart';
import 'user_initializer_screen.dart';
import 'mission_initializer_screen.dart';
import 'mission_challenge_initializer_screen.dart';
import '../kkaezam/qr/generate_self_wake_qr_screen.dart'; // 스스로 기상 QR import
import 'qr_test_screen.dart'; // ✅ 새로 추가: QR 테스트 화면 import

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 홈'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          // ✅ 혹시 버튼 많아지면 스크롤 가능하게
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAdminButton(
                context,
                label: '좌석 전체 초기화',
                icon: Icons.refresh,
                color: Colors.redAccent,
                screen: const SeatInitializerScreen(),
              ),
              const SizedBox(height: 20),
              _buildAdminButton(
                context,
                label: '회원 포인트 관리',
                icon: Icons.people,
                color: Colors.blueAccent,
                screen: const UserPointScreen(),
              ),
              const SizedBox(height: 20),
              _buildAdminButton(
                context,
                label: '유저 정보 초기화',
                icon: Icons.person_add,
                color: Colors.green,
                screen: const UserInitializerScreen(),
              ),
              const SizedBox(height: 20),
              _buildAdminButton(
                context,
                label: '미션 초기화',
                icon: Icons.flag,
                color: Colors.deepPurple,
                screen: const MissionInitializerScreen(),
              ),
              const SizedBox(height: 20),
              _buildAdminButton(
                context,
                label: '도전 미션 초기화',
                icon: Icons.flag_circle,
                color: Colors.deepOrangeAccent,
                screen: const MissionChallengeInitializerScreen(),
              ),
              const SizedBox(height: 20),
              _buildAdminButton(
                context,
                label: '스스로 기상 QR 보기',
                icon: Icons.qr_code,
                color: Colors.teal,
                screen: const GenerateSelfWakeQrScreen(),
              ),
              const SizedBox(height: 20),
              _buildAdminButton(
                context,
                label: 'QR 코드 테스트',
                icon: Icons.qr_code_scanner,
                color: Colors.amber,
                screen: const QrTestScreen(), // ✅ 여기 추가
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 버튼 생성 메소드
  Widget _buildAdminButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}

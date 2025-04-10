import 'package:flutter/material.dart';
import '../kkaezam/kkaezam_home_screen.dart';
import '../../widgets/common/service_square_button.dart'; // ✅ 경로 주의

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CNUITY 홈'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            ServiceSquareButton(
              label: '깨잠!',
              icon: Icons.bedtime,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => KkaezamHomeScreen()),
                );
              },
            ),
            // 앞으로 추가될 서비스 버튼들 여기에 넣으면 됨
          ],
        ),
      ),
    );
  }
}

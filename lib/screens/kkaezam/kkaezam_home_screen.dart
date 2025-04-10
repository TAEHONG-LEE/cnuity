import 'package:flutter/material.dart';
import '../../widgets/common/service_square_button.dart';
import 'kkaezam_seat_select_screen.dart';

class KkaezamHomeScreen extends StatelessWidget {
  KkaezamHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('깨잠! 홈'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // 좌측 상단: 좌석 선택
            ServiceSquareButton(
              label: '좌석 선택',
              icon: Icons.event_seat,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => KkaezamSeatSelectScreen()),
                );
              },
            ),
            // 우측 상단: 미션
            ServiceSquareButton(
              label: '미션',
              icon: Icons.flag,
              onTap: () {
                // TODO: 미션 페이지로 이동
              },
            ),
            // 좌측 하단: 잠자기
            ServiceSquareButton(
              label: '잠자기',
              icon: Icons.bed,
              onTap: () {
                // TODO: 타이머 실행 페이지로 이동
              },
            ),
            // 우측 하단: 나의 기록
            ServiceSquareButton(
              label: '나의 기록',
              icon: Icons.bar_chart,
              onTap: () {
                // TODO: 결과/기록 페이지로 이동
              },
            ),
          ],
        ),
      ),
    );
  }
}

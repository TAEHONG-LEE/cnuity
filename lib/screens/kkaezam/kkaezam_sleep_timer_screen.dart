import 'package:flutter/material.dart';
import '../../widgets/kkaezam/sleep_timer_section.dart';

class KkaezamSleepTimerScreen extends StatelessWidget {
  const KkaezamSleepTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('잠자기 타이머'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SleepTimerSection(
            onFinish: () {
              Navigator.pop(context); // 기상 후 돌아가기
            },
          ),
        ),
      ),
    );
  }
}

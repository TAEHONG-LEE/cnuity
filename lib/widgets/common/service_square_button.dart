// lib/widgets/common/service_square_button.dart
import 'package:flutter/material.dart';

class ServiceSquareButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const ServiceSquareButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF5197FF), // 기존 배경색 유지
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.2), // 탭 시 물결 효과
        highlightColor: Colors.black.withOpacity(0.1), // 눌림 시 어두운 효과
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

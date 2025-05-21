import 'package:flutter/material.dart';

class SeatBox extends StatelessWidget {
  final int number;
  final Color color;
  final VoidCallback onTap;
  final Widget? overlay;
  final Color borderColor; // ✅ 추가

  const SeatBox({
    super.key,
    required this.number,
    required this.color,
    required this.onTap,
    this.overlay,
    this.borderColor = Colors.transparent, // 기본은 없음
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor, // ✅ 내부에서 그리는 테두리
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (overlay != null) Positioned(top: 4, right: 4, child: overlay!),
        ],
      ),
    );
  }
}

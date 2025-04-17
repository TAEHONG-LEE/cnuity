import 'package:flutter/material.dart';

class SeatBox extends StatelessWidget {
  final int number;
  final Color color;
  final VoidCallback onTap;
  final Widget? overlay;

  const SeatBox({
    super.key,
    required this.number,
    required this.color,
    required this.onTap,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (overlay != null) Positioned(top: 2, right: 2, child: overlay!),
          ],
        ),
      ),
    );
  }
}

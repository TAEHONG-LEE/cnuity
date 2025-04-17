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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
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

import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final Color color;
  final VoidCallback? onPressed;

  const CustomBackButton({super.key, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed ?? () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
    );
  }
}

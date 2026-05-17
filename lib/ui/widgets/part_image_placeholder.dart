import 'package:flutter/material.dart';

class PartImagePlaceholder extends StatelessWidget {
  final double? height;
  final double? width;
  final Color? bgColor;
  final double iconSize;

  const PartImagePlaceholder({
    super.key,
    this.height,
    this.width,
    this.bgColor,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      color: bgColor ?? const Color(0xFF161B1F),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.two_wheeler,
              size: iconSize,
              color: const Color(0xFF01C9F5).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(
                color: const Color(0xFF90A4AE).withValues(alpha: 0.5),
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

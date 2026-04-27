import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _BackgroundPainter(
            animationValue: _controller.value,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  _BackgroundPainter({required this.animationValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Base background
    final bgPaint =
        Paint()
          ..color =
              isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Animated gradient orbs
    _drawOrb(
      canvas,
      Offset(
        size.width * 0.2 + math.sin(animationValue * 2 * math.pi) * 100,
        size.height * 0.3 + math.cos(animationValue * 2 * math.pi) * 80,
      ),
      300,
      isDark
          ? const Color(0xFF6C63FF).withValues(alpha: 0.08)
          : const Color(0xFF6C63FF).withValues(alpha: 0.06),
    );

    _drawOrb(
      canvas,
      Offset(
        size.width * 0.8 +
            math.cos(animationValue * 2 * math.pi + 1) * 120,
        size.height * 0.2 +
            math.sin(animationValue * 2 * math.pi + 1) * 60,
      ),
      250,
      isDark
          ? const Color(0xFFFF6584).withValues(alpha: 0.06)
          : const Color(0xFFFF6584).withValues(alpha: 0.04),
    );

    _drawOrb(
      canvas,
      Offset(
        size.width * 0.5 +
            math.sin(animationValue * 2 * math.pi + 2) * 80,
        size.height * 0.7 +
            math.cos(animationValue * 2 * math.pi + 2) * 100,
      ),
      280,
      isDark
          ? const Color(0xFF43E97B).withValues(alpha: 0.05)
          : const Color(0xFF43E97B).withValues(alpha: 0.04),
    );

    // Grid pattern
    if (isDark) {
      final gridPaint =
          Paint()
            ..color = Colors.white.withValues(alpha: 0.02)
            ..strokeWidth = 0.5
            ..style = PaintingStyle.stroke;

      const gridSize = 80.0;
      for (double x = 0; x < size.width; x += gridSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += gridSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color) {
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(
            Rect.fromCircle(center: center, radius: radius),
          );
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedBackground> createState() =>
      _AnimatedBackgroundState();
}

class _AnimatedBackgroundState
    extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                  -1 + controller.value,
                  -1),
              end: Alignment(
                  1,
                  1 - controller.value),
              colors: const [
                Color(0xff1A103C), // Adjusted purple tint to be slightly darker background
                Color(0xff0A2540), // Adjusted cyan tint to be slightly darker background
                Color(0xff0B1020), // Deep space cyber background
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class FloatingParticles extends StatefulWidget {
  const FloatingParticles({super.key});

  @override
  State<FloatingParticles> createState() =>
      _FloatingParticlesState();
}

class _FloatingParticlesState
    extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {

        return CustomPaint(
          painter: ParticlePainter(
            controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {

  final double value;

  ParticlePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06);

    for (int i = 0; i < 40; i++) {
      // Create unique trajectory for each particle
      double speedFactorX = sin(i * 9.8) * 40.0;
      double speedFactorY = cos(i * 12.3) * 60.0;

      double x = (i * (size.width / 40.0) + value * speedFactorX * 3) % size.width;
      double y = (i * (size.height / 40.0) + value * speedFactorY * 5) % size.height;

      // Wrap-around coordinates checking
      if (x < 0) x += size.width;
      if (y < 0) y += size.height;

      canvas.drawCircle(
        Offset(x, y),
        (i % 3 + 1.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      true;
}

class PremiumBackgroundWrapper extends StatelessWidget {
  final Widget child;

  const PremiumBackgroundWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBackground(child: const SizedBox.expand()),
        const FloatingParticles(),
        child,
      ],
    );
  }
}

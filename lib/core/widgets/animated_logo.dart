import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedLogo extends StatefulWidget {
  final double size;
  const AnimatedLogo({super.key, this.size = 120});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // ±3 degrees in radians is roughly ±0.052 radians
    _rotateAnimation = Tween<double>(begin: -0.052, end: 0.052).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: SizedBox(
              width: widget.size + 40,
              height: widget.size + 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glowing aura
                  Container(
                    width: widget.size - 10,
                    height: widget.size - 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff7C4DFF).withValues(alpha: 0.5),
                          blurRadius: _glowAnimation.value + 10,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: const Color(0xff00E5FF).withValues(alpha: 0.3),
                          blurRadius: _glowAnimation.value,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  
                  // Main Logo container
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff7C4DFF),
                          Color(0xff00E5FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(widget.size * 0.28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 2.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Q',
                      style: GoogleFonts.outfit(
                        fontSize: widget.size * 0.55,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                            color: Colors.black45,
                            offset: Offset(2, 3),
                            blurRadius: 4,
                          ),
                          Shadow(
                            color: const Color(0xff00E5FF).withValues(alpha: 0.8),
                            offset: Offset.zero,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top lightning bolt ⚡
                  Positioned(
                    top: 0,
                    child: Transform.scale(
                      scale: 1.2,
                      child: Text(
                        '⚡',
                        style: GoogleFonts.poppins(
                          fontSize: widget.size * 0.28,
                          shadows: [
                            BoxShadow(
                              color: const Color(0xff00E5FF).withValues(alpha: 0.8),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom brain 🧠
                  Positioned(
                    bottom: 0,
                    child: Transform.scale(
                      scale: 1.2,
                      child: Text(
                        '🧠',
                        style: GoogleFonts.poppins(
                          fontSize: widget.size * 0.28,
                          shadows: [
                            BoxShadow(
                              color: const Color(0xff7C4DFF).withValues(alpha: 0.8),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

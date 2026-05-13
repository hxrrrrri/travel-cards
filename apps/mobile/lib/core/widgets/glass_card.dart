import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Frosted glass card — blurs everything behind it.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double blur;
  final double borderOpacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.color,
    this.gradient,
    this.onTap,
    this.blur = 16,
    this.borderOpacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? (color ?? AppTheme.surface.withOpacity(0.75))
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: 1,
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(margin: margin, child: inner),
      );
    }
    return Container(margin: margin, child: inner);
  }
}

/// Gradient-filled bento card (no blur — opaque).
class BentoCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? height;

  const BentoCard({
    super.key,
    required this.child,
    this.gradient,
    this.color,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 24,
    this.onTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? (color ?? AppTheme.surfaceElevated) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 0.5),
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}

/// Dotted background painter for screens.
class DotPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double radius;

  const DotPatternPainter({
    this.color = const Color(0xFF1A1A2A),
    this.spacing = 24,
    this.radius = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Screen scaffold with dot-pattern background.
class DottedBackground extends StatelessWidget {
  final Widget child;

  const DottedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: const DotPatternPainter(),
            ),
          ),
          child,
        ],
      );
}

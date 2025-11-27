import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomLoading extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const CustomLoading({
    super.key,
    this.size = 50,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final loadingColor = color ?? Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeIn(duration: 300.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.easeOut,
            ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: loadingColor,
                ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ],
    );
  }
}

/// Loading con puntos animados
class DotLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;

  const DotLoadingIndicator({
    super.key,
    this.color,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = color ?? Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: size / 4),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeOut(
              delay: (index * 200).ms,
              duration: 600.ms,
            )
            .then()
            .fadeIn(duration: 600.ms);
      }),
    );
  }
}

/// Shimmer loading - placeholder animado
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1500.ms,
          color: highlightColor,
          angle: 0,
        );
  }
}

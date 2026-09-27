import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';

/// A short, accessible entrance transition. It automatically becomes static
/// when the platform requests reduced motion.
class StaggeredReveal extends StatelessWidget {
  const StaggeredReveal({
    super.key,
    required this.child,
    this.order = 0,
    this.offset = const Offset(0, .08),
  });

  final Widget child;
  final int order;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.reveal + Duration(milliseconds: order * 65),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: Curves.easeOut.transform(value),
        child: Transform.translate(
          offset: Offset(offset.dx * 40, offset.dy * 40) * (1 - value),
          child: child,
        ),
      ),
    );
  }
}

/// Adds a restrained scale response and optional haptic feedback to custom
/// surfaces without changing their semantics.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.haptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final bool haptics;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: widget.onTap != null,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => pressed = true),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => pressed = false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => pressed = false);
              if (widget.haptics) HapticFeedback.selectionClick();
              widget.onTap?.call();
            },
      child: AnimatedScale(
        scale: pressed ? .975 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    ),
  );
}

class AmbientPageBackground extends StatelessWidget {
  const AmbientPageBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8FAFE), AppColors.background],
        stops: [0, .42],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          top: -120,
          right: -110,
          child: IgnorePointer(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: .10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    ),
  );
}

class StatusPulse extends StatefulWidget {
  const StatusPulse({super.key, this.color = AppColors.primaryGreen});
  final Color color;

  @override
  State<StatusPulse> createState() => _StatusPulseState();
}

class _StatusPulseState extends State<StatusPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: AppDurations.pulse,
  )..forward();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return _dot(1, .12);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) =>
          _dot(1 + controller.value * .85, .18 * (1 - controller.value)),
    );
  }

  Widget _dot(double scale, double haloOpacity) => SizedBox(
    width: 16,
    height: 16,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.scale(
          scale: scale,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: haloOpacity),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    ),
  );
}

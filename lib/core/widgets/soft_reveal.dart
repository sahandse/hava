import 'package:flutter/material.dart';

class SoftReveal extends StatelessWidget {
  const SoftReveal({
    required this.child,
    this.offset = 10,
    this.duration = const Duration(milliseconds: 420),
    super.key,
  });

  final Widget child;
  final double offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

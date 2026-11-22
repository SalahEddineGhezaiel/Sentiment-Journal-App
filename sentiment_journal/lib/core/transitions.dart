import 'package:flutter/material.dart';

/// Custom page transition animation
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Duration reverseDuration;

  FadeSlidePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
    this.reverseDuration = const Duration(milliseconds: 300),
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade in/out
      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      );

      // Slide in from bottom
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      );

      // Reverse slide animation for when leaving
      final reverseSlideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0.0, 0.05),
      ).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOut),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: SlideTransition(
            position: reverseSlideAnimation,
            child: child,
          ),
        ),
      );
    },
  );
}

/// Navigate with smooth transition
Future<T?> navigateWithTransition<T>(
  BuildContext context,
  Widget page, {
  bool replace = false,
}) {
  final route = FadeSlidePageRoute<T>(page: page);
  if (replace) {
    return Navigator.of(context).pushReplacement(route);
  } else {
    return Navigator.of(context).push(route);
  }
}

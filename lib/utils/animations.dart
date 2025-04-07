import 'package:flutter/material.dart';

class AppAnimations {
  
  static Widget fadeIn({
    required Widget child,
    required bool animate,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedOpacity(
      opacity: animate ? 1.0 : 0.0,
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  
  static Widget slideIn({
    required Widget child,
    required bool animate,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    Offset beginOffset = const Offset(0.0, 0.5),
  }) {
    return AnimatedSlide(
      offset: animate ? Offset.zero : beginOffset,
      duration: duration,
      curve: curve,
      child: AnimatedOpacity(
        opacity: animate ? 1.0 : 0.0,
        duration: duration,
        curve: curve,
        child: child,
      ),
    );
  }

  
  static Widget scale({
    required Widget child,
    required bool animate,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double beginScale = 0.8,
  }) {
    return AnimatedScale(
      scale: animate ? 1.0 : beginScale,
      duration: duration,
      curve: curve,
      child: AnimatedOpacity(
        opacity: animate ? 1.0 : 0.0,
        duration: duration,
        curve: curve,
        child: child,
      ),
    );
  }

  
  static Widget animatedContainer({
    required Widget child,
    required bool animate,
    required double beginWidth,
    required double endWidth,
    required double beginHeight,
    required double endHeight,
    Color? beginColor,
    Color? endColor,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: animate ? endWidth : beginWidth,
      height: animate ? endHeight : beginHeight,
      color: animate ? endColor : beginColor,
      child: child,
    );
  }

  
  static Route<T> pageTransition<T>({
    required Widget page,
    bool rightToLeft = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = Offset(rightToLeft ? 1.0 : -1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  
  static Duration staggeredDuration(int index, {int delayMs = 50}) {
    return Duration(milliseconds: 300 + (index * delayMs));
  }
}
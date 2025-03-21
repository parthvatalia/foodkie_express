import 'package:flutter/material.dart';

class AnimatedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AnimatedButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width = double.infinity,
    this.height = 48,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
          foregroundColor: foregroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: isLoading
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              foregroundColor ?? Colors.white,
            ),
          ),
        )
            : child,
      ),
    );
  }
}
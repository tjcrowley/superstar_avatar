import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null 
            ? AppConstants.primaryGradient 
            : LinearGradient(
                colors: [
                  AppConstants.textSecondaryColor.withOpacity(0.3),
                  AppConstants.textSecondaryColor.withOpacity(0.3),
                ],
              ),
        borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadiusL),
        boxShadow: onPressed != null ? AppConstants.shadowMedium : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadiusL),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingL,
              vertical: AppConstants.spacingM,
            ),
            child: Center(
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppConstants.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
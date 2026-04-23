import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum NumbiaButtonVariant { primary, secondary, text }

/// Reusable button component following the NUMBIA design system.
class NumbiaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final NumbiaButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  const NumbiaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = NumbiaButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case NumbiaButtonVariant.primary:
        return SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: _buildChild(Colors.white),
          ),
        );
      case NumbiaButtonVariant.secondary:
        return SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: _buildChild(AppColors.secondary),
          ),
        );
      case NumbiaButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(AppColors.primary),
        );
    }
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.button.copyWith(color: color)),
        ],
      );
    }

    return Text(label, style: AppTypography.button.copyWith(color: color));
  }
}

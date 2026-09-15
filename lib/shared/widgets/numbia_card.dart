import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Reusable card component.
class NumbiaCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool selected;

  const NumbiaCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : AppColors.surface,
        borderRadius: radius,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.divider,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          // Give a visible, but not too strong, tactile response to a tap
          // (Material state-layer feedback) without adding any extra
          // dependency — plain Material/InkWell already provides this.
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// NUMBIA logo / brand mark widget.
class LogoWidget extends StatelessWidget {
  final double size;
  final bool showTagline;

  const LogoWidget({
    super.key,
    this.size = 48,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.25),
          ),
          child: Center(
            child: Text(
              'N',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('NUMBAA', style: AppTypography.h1),
        if (showTagline) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Votre business, en ligne',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutralMid,
            ),
          ),
        ],
      ],
    );
  }
}

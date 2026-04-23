import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/logo_widget.dart';
import '../../../../shared/widgets/numbia_button.dart';

/// Ce screen n'est plus utilise dans le flux principal (auth par telephone).
/// Il redirige vers /language.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LogoWidget(size: 56, showTagline: true),
              const SizedBox(height: AppSpacing.xxl),
              Text('Connexion', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'L\'authentification se fait desormais par numero de telephone.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.neutralMid),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              NumbiaButton(
                label: 'Continuer avec mon telephone',
                icon: Icons.phone_outlined,
                onPressed: () => context.go('/language'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

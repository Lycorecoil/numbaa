import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/usecases/auth/set_password_use_case.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../cubits/auth_cubit.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (password.length < 6) {
      setState(() => _error = 'Le mot de passe doit faire au moins 6 caractères.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await getIt<SetPasswordUseCase>().call(password);
      if (!mounted) return;
      final user = context.read<AuthCubit>().state.user;
      if (user?.hasCompletedOnboarding == true) {
        context.go('/dashboard');
      } else {
        context.go('/setup');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Créer un mot de passe', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ce mot de passe vous permettra de vous connecter rapidement sans code OTP.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.neutralMid),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Text('Mot de passe', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure1,
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: 'Au moins 6 caractères',
                  hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.neutralMid),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: AppSpacing.md),
              Text('Confirmer le mot de passe', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscure2,
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: 'Répétez le mot de passe',
                  hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.neutralMid),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.error)),
              ],

              const Spacer(),

              NumbiaButton(
                label: 'Définir mon mot de passe',
                isLoading: _loading,
                onPressed: _passwordCtrl.text.isNotEmpty && _confirmCtrl.text.isNotEmpty
                    ? _submit
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

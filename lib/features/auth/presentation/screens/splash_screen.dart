import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo_widget.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';

/// Splash screen — brand moment + auth routing.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.read<AuthCubit>().checkAuthStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          if (state.user!.hasCompletedOnboarding) {
            context.go('/dashboard');
          } else {
            context.go('/setup');
          }
        } else if (state.status == AuthStatus.unauthenticated) {
          context.go('/login');
        }
      },
      child: const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: LogoWidget(size: 72, showTagline: true),
        ),
      ),
    );
  }
}

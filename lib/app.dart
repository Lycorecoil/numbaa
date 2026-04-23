import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/usecases/auth/check_auth_status_use_case.dart';
import 'domain/usecases/auth/logout_use_case.dart';
import 'domain/usecases/auth/mark_onboarding_complete_use_case.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';

/// Root widget for the NUMBAA application.
class NumbiaApp extends StatelessWidget {
  const NumbiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(
        checkAuthStatus: getIt<CheckAuthStatusUseCase>(),
        logout: getIt<LogoutUseCase>(),
        markOnboardingComplete: getIt<MarkOnboardingCompleteUseCase>(),
      ),
      child: Builder(
        builder: (context) {
          final authCubit = context.read<AuthCubit>();
          final router = buildRouter(authCubit);

          return MaterialApp.router(
            title: 'NUMBAA',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}

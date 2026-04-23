import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../domain/usecases/auth/check_auth_status_use_case.dart';
import '../../../../domain/usecases/auth/logout_use_case.dart';
import '../../../../domain/usecases/auth/mark_onboarding_complete_use_case.dart';
import 'auth_state.dart';

/// Manages authentication state across the app.
class AuthCubit extends Cubit<AuthState> {
  final CheckAuthStatusUseCase _checkAuthStatus;
  final LogoutUseCase _logout;
  final MarkOnboardingCompleteUseCase _markOnboardingComplete;

  AuthCubit({
    required CheckAuthStatusUseCase checkAuthStatus,
    required LogoutUseCase logout,
    required MarkOnboardingCompleteUseCase markOnboardingComplete,
  })  : _checkAuthStatus = checkAuthStatus,
        _logout = logout,
        _markOnboardingComplete = markOnboardingComplete,
        super(const AuthState());

  /// Check if a user session exists on app start.
  Future<void> checkAuthStatus() async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _checkAuthStatus();
      if (user != null) {
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  /// Called after OTP verification to persist user in state.
  void setUser(UserEntity user) {
    emit(state.copyWith(status: AuthStatus.authenticated, user: user));
  }

  Future<void> logout() async {
    await _logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> markOnboardingComplete() async {
    if (state.user == null) return;
    await _markOnboardingComplete(state.user!.id);
    emit(state.copyWith(
      user: state.user!.copyWith(hasCompletedOnboarding: true),
    ));
  }
}

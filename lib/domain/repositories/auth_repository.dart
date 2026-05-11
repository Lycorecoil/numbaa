import '../entities/user_entity.dart';
import '../../core/constants/enums.dart';

class OtpVerificationResult {
  final UserEntity user;
  final bool needsPassword;
  OtpVerificationResult({required this.user, required this.needsPassword});
}

/// Contract for phone-based authentication operations.
abstract class AuthRepository {
  /// Send OTP to the given phone number.
  /// Returns the debug code when the server is in bypass mode (testing only).
  Future<String?> requestOtp(String phone);

  /// Verify OTP and return the user (created or found) + whether password setup is needed.
  Future<OtpVerificationResult> verifyOtp(String phone, String code, AppLanguage language);

  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<void> markOnboardingComplete(String userId);
  Future<UserEntity> loginWithPassword(String phone, String password);
  Future<void> setPassword(String password);
}

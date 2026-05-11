import '../entities/user_entity.dart';
import '../../core/constants/enums.dart';

/// Contract for phone-based authentication operations.
abstract class AuthRepository {
  /// Send OTP to the given phone number.
  /// Returns the debug code when the server is in bypass mode (testing only).
  Future<String?> requestOtp(String phone);

  /// Verify OTP and return the user (created or found).
  Future<UserEntity> verifyOtp(String phone, String code, AppLanguage language);

  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<void> markOnboardingComplete(String userId);
}

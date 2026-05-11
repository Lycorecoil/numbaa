import '../../core/constants/enums.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class HttpAuthRepository implements AuthRepository {
  final ApiClient _api;
  HttpAuthRepository(this._api);

  @override
  Future<String?> requestOtp(String phone) async {
    final res = await _api.post('/auth/request-otp', {'phone': phone}, auth: false);
    return res['debugCode'] as String?;
  }

  @override
  Future<UserEntity> verifyOtp(String phone, String code, AppLanguage language) async {
    final res = await _api.post('/auth/verify-otp', {
      'phone': phone,
      'code': code,
      'language': language.name,
    }, auth: false);
    await _api.saveToken(res['token'] as String);
    return _userFromMap(res['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await _api.getToken();
    if (token == null) return null;
    try {
      final res = await _api.get('/auth/me');
      return _userFromMap(res['user'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _api.deleteToken();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', {});
    } finally {
      await _api.deleteToken();
    }
  }

  @override
  Future<void> markOnboardingComplete(String userId) async {
    await _api.patch('/auth/onboarding', {'hasCompletedOnboarding': true});
  }

  UserEntity _userFromMap(Map<String, dynamic> m) => UserEntity(
        id: m['id'] as String,
        phone: m['phone'] as String,
        name: m['name'] as String? ?? '',
        language: AppLanguage.values.firstWhere(
          (l) => l.name == m['language'],
          orElse: () => AppLanguage.french,
        ),
        hasCompletedOnboarding: m['hasCompletedOnboarding'] as bool? ?? false,
      );
}

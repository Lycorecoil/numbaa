import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Mock implementation of [AuthRepository] using SharedPreferences.
/// OTP verification always succeeds with code "1234".
class MockAuthRepository implements AuthRepository {
  static const _usersKey = 'numbaa_users';
  static const _currentUserKey = 'numbaa_current_user';

  final _uuid = const Uuid();

  @override
  Future<String?> requestOtp(String phone) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  @override
  Future<UserEntity> verifyOtp(
      String phone, String code, AppLanguage language) async {
    if (code != AppConstants.mockOtpCode) {
      throw Exception('Code incorrect. Veuillez reessayer.');
    }

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    final users = usersJson != null
        ? Map<String, dynamic>.from(jsonDecode(usersJson))
        : <String, dynamic>{};

    // Find existing user by phone
    for (final userData in users.values) {
      if (userData['phone'] == phone) {
        final userId = userData['id'] as String;
        await prefs.setString(_currentUserKey, userId);
        return UserEntity(
          id: userId,
          phone: phone,
          name: userData['name'] ?? '',
          language: AppLanguage.values.firstWhere(
            (l) => l.name == (userData['language'] ?? 'french'),
            orElse: () => AppLanguage.french,
          ),
          hasCompletedOnboarding:
              userData['hasCompletedOnboarding'] ?? false,
        );
      }
    }

    // New user
    final userId = _uuid.v4();
    final userData = {
      'id': userId,
      'phone': phone,
      'name': '',
      'language': language.name,
      'hasCompletedOnboarding': false,
    };
    users[userId] = userData;
    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setString(_currentUserKey, userId);

    return UserEntity(id: userId, phone: phone, language: language);
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_currentUserKey);
    if (userId == null) return null;

    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return null;

    final users = Map<String, dynamic>.from(jsonDecode(usersJson));
    final userData = users[userId];
    if (userData == null) return null;

    return UserEntity(
      id: userData['id'],
      phone: userData['phone'] ?? '',
      name: userData['name'] ?? '',
      language: AppLanguage.values.firstWhere(
        (l) => l.name == (userData['language'] ?? 'french'),
        orElse: () => AppLanguage.french,
      ),
      hasCompletedOnboarding: userData['hasCompletedOnboarding'] ?? false,
    );
  }

  @override
  Future<void> markOnboardingComplete(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return;

    final users = Map<String, dynamic>.from(jsonDecode(usersJson));
    if (users[userId] != null) {
      users[userId]['hasCompletedOnboarding'] = true;
      await prefs.setString(_usersKey, jsonEncode(users));
    }
  }
}

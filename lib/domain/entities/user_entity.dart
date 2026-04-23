import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

/// Represents an authenticated user.
class UserEntity extends Equatable {
  final String id;
  final String phone;
  final String name;
  final AppLanguage language;
  final bool hasCompletedOnboarding;

  const UserEntity({
    required this.id,
    required this.phone,
    this.name = '',
    this.language = AppLanguage.french,
    this.hasCompletedOnboarding = false,
  });

  UserEntity copyWith({
    String? id,
    String? phone,
    String? name,
    AppLanguage? language,
    bool? hasCompletedOnboarding,
  }) {
    return UserEntity(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      language: language ?? this.language,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  @override
  List<Object?> get props => [id, phone, name, language, hasCompletedOnboarding];
}

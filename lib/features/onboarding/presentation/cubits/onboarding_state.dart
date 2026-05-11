import 'package:equatable/equatable.dart';
import '../../../../core/constants/enums.dart';

class OnboardingState extends Equatable {
  final AppLanguage language;
  final String countryCode;
  final String phone;
  final bool otpSent;
  final bool otpVerified;
  final String businessName;
  final BusinessCategory? businessCategory;
  final String? logoPath;
  final String whatsapp;
  final bool isLoading;
  final String? error;
  final String? debugCode;
  final bool needsPassword;

  const OnboardingState({
    this.language = AppLanguage.french,
    this.countryCode = '+226',
    this.phone = '',
    this.otpSent = false,
    this.otpVerified = false,
    this.businessName = '',
    this.businessCategory,
    this.logoPath,
    this.whatsapp = '',
    this.isLoading = false,
    this.error,
    this.debugCode,
    this.needsPassword = false,
  });

  OnboardingState copyWith({
    AppLanguage? language,
    String? countryCode,
    String? phone,
    bool? otpSent,
    bool? otpVerified,
    String? businessName,
    BusinessCategory? businessCategory,
    String? logoPath,
    String? whatsapp,
    bool? isLoading,
    String? error,
    String? debugCode,
    bool? needsPassword,
  }) {
    return OnboardingState(
      language: language ?? this.language,
      countryCode: countryCode ?? this.countryCode,
      phone: phone ?? this.phone,
      otpSent: otpSent ?? this.otpSent,
      otpVerified: otpVerified ?? this.otpVerified,
      businessName: businessName ?? this.businessName,
      businessCategory: businessCategory ?? this.businessCategory,
      logoPath: logoPath ?? this.logoPath,
      whatsapp: whatsapp ?? this.whatsapp,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      debugCode: debugCode,
      needsPassword: needsPassword ?? this.needsPassword,
    );
  }

  String get fullPhone => '$countryCode$phone';

  @override
  List<Object?> get props => [
        language,
        countryCode,
        phone,
        otpSent,
        otpVerified,
        businessName,
        businessCategory,
        logoPath,
        whatsapp,
        isLoading,
        error,
        debugCode,
        needsPassword,
      ];
}

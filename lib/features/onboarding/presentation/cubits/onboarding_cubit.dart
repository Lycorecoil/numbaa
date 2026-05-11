import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/enums.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../domain/usecases/auth/mark_onboarding_complete_use_case.dart';
import '../../../../domain/usecases/auth/request_otp_use_case.dart';
import '../../../../domain/usecases/auth/verify_otp_use_case.dart';
import '../../../../domain/usecases/business/save_business_use_case.dart';
import 'onboarding_state.dart';

/// Manages the full onboarding flow:
/// language → phone → OTP → business setup → dashboard.
class OnboardingCubit extends Cubit<OnboardingState> {
  final RequestOtpUseCase _requestOtp;
  final VerifyOtpUseCase _verifyOtp;
  final SaveBusinessUseCase _saveBusiness;
  final MarkOnboardingCompleteUseCase _markOnboardingComplete;

  UserEntity? _pendingUser;

  OnboardingCubit({
    required RequestOtpUseCase requestOtp,
    required VerifyOtpUseCase verifyOtp,
    required SaveBusinessUseCase saveBusiness,
    required MarkOnboardingCompleteUseCase markOnboardingComplete,
  })  : _requestOtp = requestOtp,
        _verifyOtp = verifyOtp,
        _saveBusiness = saveBusiness,
        _markOnboardingComplete = markOnboardingComplete,
        super(const OnboardingState());

  // --- Step 1: Language ---
  void setLanguage(AppLanguage language) {
    emit(state.copyWith(language: language));
  }

  // --- Step 2: Phone ---
  void setCountryCode(String code) {
    emit(state.copyWith(countryCode: code));
  }

  void setPhone(String phone) {
    emit(state.copyWith(phone: phone));
  }

  Future<bool> sendOtp() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final debugCode = await _requestOtp(state.fullPhone);
      emit(state.copyWith(isLoading: false, otpSent: true, debugCode: debugCode));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
      return false;
    }
  }

  // --- Step 3: OTP ---
  Future<UserEntity?> verifyOtp(String code) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final result = await _verifyOtp(state.fullPhone, code, state.language);
      _pendingUser = result.user;
      emit(state.copyWith(
        isLoading: false,
        otpVerified: true,
        needsPassword: result.needsPassword,
      ));
      return result.user;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
      return null;
    }
  }

  // --- Step 4: Business info ---
  void setBusinessName(String name) {
    emit(state.copyWith(businessName: name));
  }

  void setBusinessCategory(BusinessCategory category) {
    emit(state.copyWith(businessCategory: category));
  }

  void setLogoPath(String? path) {
    emit(state.copyWith(logoPath: path));
  }

  void setWhatsapp(String whatsapp) {
    emit(state.copyWith(whatsapp: whatsapp));
  }

  bool canCompleteSetup() {
    return state.businessName.trim().isNotEmpty &&
        state.businessCategory != null;
  }

  Future<bool> completeSetup() async {
    if (_pendingUser == null) return false;
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _saveBusiness(
        userId: _pendingUser!.id,
        name: state.businessName.trim(),
        category: state.businessCategory!,
        logoPath: state.logoPath,
        whatsapp: state.whatsapp,
      );
      await _markOnboardingComplete(_pendingUser!.id);

      emit(state.copyWith(isLoading: false));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la sauvegarde: ${e.toString()}',
      ));
      return false;
    }
  }

  UserEntity? get pendingUser => _pendingUser;
}

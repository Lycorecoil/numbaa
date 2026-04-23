import '../../repositories/auth_repository.dart';

class RequestOtpUseCase {
  final AuthRepository _repository;
  RequestOtpUseCase(this._repository);

  Future<void> call(String phone) => _repository.requestOtp(phone);
}

import '../../repositories/auth_repository.dart';

class MarkOnboardingCompleteUseCase {
  final AuthRepository _repository;
  MarkOnboardingCompleteUseCase(this._repository);

  Future<void> call(String userId) =>
      _repository.markOnboardingComplete(userId);
}

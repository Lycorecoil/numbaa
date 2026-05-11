import '../../repositories/auth_repository.dart';

class SetPasswordUseCase {
  final AuthRepository _repository;
  SetPasswordUseCase(this._repository);

  Future<void> call(String password) => _repository.setPassword(password);
}

import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class LoginWithPasswordUseCase {
  final AuthRepository _repository;
  LoginWithPasswordUseCase(this._repository);

  Future<UserEntity> call(String phone, String password) =>
      _repository.loginWithPassword(phone, password);
}

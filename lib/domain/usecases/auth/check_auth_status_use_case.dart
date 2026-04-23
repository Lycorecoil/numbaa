import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository _repository;
  CheckAuthStatusUseCase(this._repository);

  Future<UserEntity?> call() => _repository.getCurrentUser();
}

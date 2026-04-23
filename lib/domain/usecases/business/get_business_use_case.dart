import '../../entities/business_entity.dart';
import '../../repositories/business_repository.dart';

class GetBusinessUseCase {
  final BusinessRepository _repository;
  GetBusinessUseCase(this._repository);

  Future<BusinessEntity?> call(String userId) =>
      _repository.getBusiness(userId);
}

import '../../entities/site_entity.dart';
import '../../repositories/site_repository.dart';

class GetSiteUseCase {
  final SiteRepository _repository;
  GetSiteUseCase(this._repository);

  Future<SiteEntity?> call(String businessId) =>
      _repository.getSite(businessId);
}

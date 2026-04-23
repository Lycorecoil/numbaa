import '../../entities/site_entity.dart';
import '../../repositories/site_repository.dart';

class PublishSiteUseCase {
  final SiteRepository _repository;
  PublishSiteUseCase(this._repository);

  Future<SiteEntity> call(String siteId) => _repository.publishSite(siteId);
}

import '../../entities/site_entity.dart';
import '../../repositories/site_repository.dart';

class UpdateSiteUseCase {
  final SiteRepository _repository;
  UpdateSiteUseCase(this._repository);

  Future<SiteEntity> call(SiteEntity site) => _repository.updateSite(site);
}

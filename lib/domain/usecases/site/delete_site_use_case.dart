import '../../repositories/site_repository.dart';

class DeleteSiteUseCase {
  final SiteRepository _repo;
  DeleteSiteUseCase(this._repo);
  Future<void> call(String siteId) => _repo.deleteSite(siteId);
}

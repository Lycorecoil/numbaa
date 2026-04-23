import '../../repositories/site_repository.dart';

class DeleteProductUseCase {
  final SiteRepository _repository;
  DeleteProductUseCase(this._repository);

  Future<void> call(String siteId, String productId) => _repository.deleteProduct(siteId, productId);
}

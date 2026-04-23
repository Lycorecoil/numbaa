import '../../entities/product_entity.dart';
import '../../repositories/site_repository.dart';

class GetProductsUseCase {
  final SiteRepository _repository;
  GetProductsUseCase(this._repository);

  Future<List<ProductEntity>> call(String siteId) =>
      _repository.getProducts(siteId);
}

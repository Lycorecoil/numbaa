import '../../entities/product_entity.dart';
import '../../repositories/site_repository.dart';

class UpdateProductUseCase {
  final SiteRepository _repository;
  UpdateProductUseCase(this._repository);

  Future<ProductEntity> call(ProductEntity product) =>
      _repository.updateProduct(product);
}

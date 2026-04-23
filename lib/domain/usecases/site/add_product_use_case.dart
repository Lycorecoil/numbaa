import '../../entities/product_entity.dart';
import '../../repositories/site_repository.dart';

class AddProductUseCase {
  final SiteRepository _repository;
  AddProductUseCase(this._repository);

  Future<ProductEntity> call(ProductEntity product) =>
      _repository.addProduct(product);
}

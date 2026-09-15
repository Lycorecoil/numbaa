import '../../repositories/site_repository.dart';

/// Uploads a photo for an existing product and returns the image URL (or
/// local file path in offline/mock mode) to store on the product.
class UploadProductImageUseCase {
  final SiteRepository _repository;
  UploadProductImageUseCase(this._repository);

  Future<String> call(String siteId, String productId, String filePath) =>
      _repository.uploadProductImage(siteId, productId, filePath);
}

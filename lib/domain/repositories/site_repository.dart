import '../entities/site_entity.dart';
import '../entities/product_entity.dart';

/// Contract for site project operations.
abstract class SiteRepository {
  Future<SiteEntity?> getSite(String businessId);
  Future<SiteEntity> createSite(SiteEntity site);
  Future<SiteEntity> updateSite(SiteEntity site);
  Future<SiteEntity> publishSite(String siteId);

  // Product operations (for e-commerce sites)
  Future<List<ProductEntity>> getProducts(String siteId);
  Future<ProductEntity> addProduct(ProductEntity product);
  Future<ProductEntity> updateProduct(ProductEntity product);
  Future<void> deleteSite(String siteId);
  Future<void> deleteProduct(String siteId, String productId);

  /// Uploads a photo for an existing product (the product must already be
  /// saved server-side, since the endpoint attaches the image by id).
  /// Returns the relative image URL to store on the product.
  Future<String> uploadProductImage(String siteId, String productId, String filePath);
}

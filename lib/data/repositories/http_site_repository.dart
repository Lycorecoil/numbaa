import '../../core/constants/enums.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/site_entity.dart';
import '../../domain/repositories/site_repository.dart';

class HttpSiteRepository implements SiteRepository {
  final ApiClient _api;
  HttpSiteRepository(this._api);

  // --- Site operations ---

  @override
  Future<SiteEntity?> getSite(String businessId) async {
    try {
      final res = await _api.get('/sites/$businessId');
      return _siteFromMap(res['site'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<SiteEntity> createSite(SiteEntity site) async {
    final res = await _api.post('/sites', _siteToMap(site));
    return _siteFromMap(res['site'] as Map<String, dynamic>);
  }

  @override
  Future<SiteEntity> updateSite(SiteEntity site) async {
    final res = await _api.put('/sites/${site.id}', _siteToMap(site));
    return _siteFromMap(res['site'] as Map<String, dynamic>);
  }

  @override
  Future<SiteEntity> publishSite(String siteId) async {
    final res = await _api.post('/sites/$siteId/publish', {});
    return _siteFromMap(res['site'] as Map<String, dynamic>);
  }

  // --- Product operations ---

  @override
  Future<List<ProductEntity>> getProducts(String siteId) async {
    final res = await _api.get('/sites/$siteId/products');
    final list = res['products'] as List<dynamic>;
    return list.map((p) => _productFromMap(p as Map<String, dynamic>)).toList();
  }

  @override
  Future<ProductEntity> addProduct(ProductEntity product) async {
    final res = await _api.post('/sites/${product.siteId}/products', _productToMap(product));
    return _productFromMap(res['product'] as Map<String, dynamic>);
  }

  @override
  Future<ProductEntity> updateProduct(ProductEntity product) async {
    final res = await _api.put('/sites/${product.siteId}/products/${product.id}', _productToMap(product));
    return _productFromMap(res['product'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteProduct(String siteId, String productId) async {
    await _api.delete('/sites/$siteId/products/$productId');
  }

  // --- Serialization ---

  Map<String, dynamic> _siteToMap(SiteEntity s) => {
        'businessId': s.businessId,
        'templateId': s.templateId,
        'websiteType': s.websiteType.name,
        'primaryColor': s.primaryColor,
        'sections': s.sections
            .map((sec) => {
                  'id': sec.id,
                  'type': sec.type.name,
                  'title': sec.title,
                  'content': sec.content,
                  'order': sec.order,
                })
            .toList(),
      };

  SiteEntity _siteFromMap(Map<String, dynamic> m) => SiteEntity(
        id: m['id'] as String,
        businessId: m['businessId'] as String,
        templateId: m['templateId'] as String,
        websiteType: WebsiteType.values.firstWhere(
          (t) => t.name == m['websiteType'],
          orElse: () => WebsiteType.showcase,
        ),
        status: SiteStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => SiteStatus.draft,
        ),
        primaryColor: m['primaryColor'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        sections: (m['sections'] as List<dynamic>? ?? [])
            .map((s) => SiteSection(
                  id: s['id'] as String,
                  type: SectionType.values.firstWhere(
                    (t) => t.name == s['type'],
                    orElse: () => SectionType.hero,
                  ),
                  title: s['title'] as String? ?? '',
                  content: s['content'] as String? ?? '',
                  order: s['order'] as int? ?? 0,
                ))
            .toList(),
      );

  Map<String, dynamic> _productToMap(ProductEntity p) => {
        'name': p.name,
        'description': p.description,
        'price': p.price,
        'imageUrl': p.imagePath,
        'category': p.category,
      };

  ProductEntity _productFromMap(Map<String, dynamic> m) => ProductEntity(
        id: m['id'] as String,
        siteId: m['siteId'] as String,
        name: m['name'] as String,
        description: m['description'] as String? ?? '',
        price: (m['price'] as num).toDouble(),
        imagePath: m['imageUrl'] as String?,
        category: m['category'] as String? ?? '',
      );
}

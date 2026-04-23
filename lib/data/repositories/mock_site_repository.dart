import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/enums.dart';
import '../../domain/entities/site_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/site_repository.dart';

/// Mock implementation of [SiteRepository] using SharedPreferences.
class MockSiteRepository implements SiteRepository {
  static const _sitesKey = 'numbia_sites';
  static const _productsKey = 'numbia_products';
  final _uuid = const Uuid();

  // --- Site operations ---

  @override
  Future<SiteEntity?> getSite(String businessId) async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString(_sitesKey);
    if (dataJson == null) return null;

    final sites = Map<String, dynamic>.from(jsonDecode(dataJson));
    for (final entry in sites.values) {
      if (entry['businessId'] == businessId) {
        return _siteFromMap(entry);
      }
    }
    return null;
  }

  @override
  Future<SiteEntity> createSite(SiteEntity site) async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString(_sitesKey);
    final sites =
        dataJson != null ? Map<String, dynamic>.from(jsonDecode(dataJson)) : {};

    final id = site.id.isEmpty ? _uuid.v4() : site.id;
    final created = site.copyWith(id: id);
    sites[id] = _siteToMap(created);

    await prefs.setString(_sitesKey, jsonEncode(sites));
    return created;
  }

  @override
  Future<SiteEntity> updateSite(SiteEntity site) async {
    return createSite(site);
  }

  @override
  Future<SiteEntity> publishSite(String siteId) async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString(_sitesKey);
    if (dataJson == null) throw Exception('Site non trouve');

    final sites = Map<String, dynamic>.from(jsonDecode(dataJson));
    final siteData = sites[siteId];
    if (siteData == null) throw Exception('Site non trouve');

    // Simulate publish delay
    await Future.delayed(const Duration(seconds: 2));

    siteData['status'] = SiteStatus.published.name;
    sites[siteId] = siteData;
    await prefs.setString(_sitesKey, jsonEncode(sites));

    return _siteFromMap(siteData);
  }

  // --- Product operations ---

  @override
  Future<List<ProductEntity>> getProducts(String siteId) async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString(_productsKey);
    if (dataJson == null) return [];

    final products = Map<String, dynamic>.from(jsonDecode(dataJson));
    return products.values
        .where((p) => p['siteId'] == siteId)
        .map((p) => _productFromMap(p))
        .toList();
  }

  @override
  Future<ProductEntity> addProduct(ProductEntity product) async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString(_productsKey);
    final products =
        dataJson != null ? Map<String, dynamic>.from(jsonDecode(dataJson)) : {};

    final id = product.id.isEmpty ? _uuid.v4() : product.id;
    final saved = product.copyWith(id: id);
    products[id] = _productToMap(saved);

    await prefs.setString(_productsKey, jsonEncode(products));
    return saved;
  }

  @override
  Future<ProductEntity> updateProduct(ProductEntity product) async {
    return addProduct(product);
  }

  @override
  Future<void> deleteProduct(String siteId, String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString(_productsKey);
    if (dataJson == null) return;

    final products = Map<String, dynamic>.from(jsonDecode(dataJson));
    products.remove(productId);
    await prefs.setString(_productsKey, jsonEncode(products));
  }

  // --- Serialization helpers ---

  Map<String, dynamic> _siteToMap(SiteEntity s) => {
        'id': s.id,
        'businessId': s.businessId,
        'templateId': s.templateId,
        'websiteType': s.websiteType.name,
        'status': s.status.name,
        'primaryColor': s.primaryColor,
        'createdAt': s.createdAt.toIso8601String(),
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

  SiteEntity _siteFromMap(Map<String, dynamic> map) => SiteEntity(
        id: map['id'],
        businessId: map['businessId'],
        templateId: map['templateId'],
        websiteType: WebsiteType.values.firstWhere(
          (t) => t.name == map['websiteType'],
          orElse: () => WebsiteType.showcase,
        ),
        status: SiteStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => SiteStatus.draft,
        ),
        primaryColor: map['primaryColor'],
        createdAt: DateTime.parse(map['createdAt']),
        sections: (map['sections'] as List? ?? [])
            .map((s) => SiteSection(
                  id: s['id'],
                  type: SectionType.values.firstWhere(
                    (t) => t.name == s['type'],
                    orElse: () => SectionType.hero,
                  ),
                  title: s['title'] ?? '',
                  content: s['content'] ?? '',
                  order: s['order'] ?? 0,
                ))
            .toList(),
      );

  Map<String, dynamic> _productToMap(ProductEntity p) => {
        'id': p.id,
        'siteId': p.siteId,
        'name': p.name,
        'description': p.description,
        'price': p.price,
        'imagePath': p.imagePath,
        'category': p.category,
      };

  ProductEntity _productFromMap(dynamic map) => ProductEntity(
        id: map['id'],
        siteId: map['siteId'],
        name: map['name'],
        description: map['description'] ?? '',
        price: (map['price'] as num).toDouble(),
        imagePath: map['imagePath'],
        category: map['category'] ?? '',
      );
}

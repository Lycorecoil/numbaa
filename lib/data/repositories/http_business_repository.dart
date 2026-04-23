import '../../core/constants/enums.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/repositories/business_repository.dart';

class HttpBusinessRepository implements BusinessRepository {
  final ApiClient _api;
  HttpBusinessRepository(this._api);

  @override
  Future<BusinessEntity?> getBusiness(String userId) async {
    try {
      final res = await _api.get('/business');
      return _fromMap(res['business'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<BusinessEntity> saveBusiness(BusinessEntity business) async {
    final res = await _api.post('/business', _toMap(business));
    return _fromMap(res['business'] as Map<String, dynamic>);
  }

  @override
  Future<BusinessEntity> updateBusiness(BusinessEntity business) async {
    final res = await _api.put('/business', _toMap(business));
    return _fromMap(res['business'] as Map<String, dynamic>);
  }

  Map<String, dynamic> _toMap(BusinessEntity b) => {
        'name': b.name,
        'category': b.category.name,
        'logoUrl': b.logoPath,
        'contactPhone': b.contact.phone,
        'contactEmail': b.contact.email,
        'contactWhatsapp': b.contact.whatsapp,
        'socialFacebook': b.socialLinks.facebook,
        'socialInstagram': b.socialLinks.instagram,
        'socialTwitter': b.socialLinks.twitter,
        'socialLinkedin': b.socialLinks.linkedin,
      };

  BusinessEntity _fromMap(Map<String, dynamic> m) => BusinessEntity(
        id: m['id'] as String,
        userId: m['userId'] as String,
        name: m['name'] as String,
        category: BusinessCategory.values.firstWhere(
          (c) => c.name == m['category'],
          orElse: () => BusinessCategory.autre,
        ),
        logoPath: m['logoUrl'] as String?,
        contact: ContactInfo(
          phone: m['contactPhone'] as String? ?? '',
          email: m['contactEmail'] as String? ?? '',
          whatsapp: m['contactWhatsapp'] as String? ?? '',
        ),
        socialLinks: SocialLinks(
          facebook: m['socialFacebook'] as String? ?? '',
          instagram: m['socialInstagram'] as String? ?? '',
          twitter: m['socialTwitter'] as String? ?? '',
          linkedin: m['socialLinkedin'] as String? ?? '',
        ),
      );
}

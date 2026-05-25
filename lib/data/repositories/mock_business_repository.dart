import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/enums.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/repositories/business_repository.dart';

/// Mock implementation of [BusinessRepository] using SharedPreferences.
class MockBusinessRepository implements BusinessRepository {
  static const _businessesKey = 'numbaa_businesses';
  final _uuid = const Uuid();

  @override
  Future<BusinessEntity?> getBusiness(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString(_businessesKey);
    if (dataJson == null) return null;

    final businesses = Map<String, dynamic>.from(jsonDecode(dataJson));
    for (final entry in businesses.values) {
      if (entry['userId'] == userId) {
        return _fromMap(entry);
      }
    }
    return null;
  }

  @override
  Future<BusinessEntity> saveBusiness(BusinessEntity business) async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString(_businessesKey);
    final businesses =
        dataJson != null ? Map<String, dynamic>.from(jsonDecode(dataJson)) : {};

    final id = business.id.isEmpty ? _uuid.v4() : business.id;
    final saved = business.copyWith(id: id);
    businesses[id] = _toMap(saved);

    await prefs.setString(_businessesKey, jsonEncode(businesses));
    return saved;
  }

  @override
  Future<BusinessEntity> updateBusiness(BusinessEntity business) async {
    return saveBusiness(business);
  }

  @override
  Future<String> uploadLogo(String filePath) async => filePath;

  Map<String, dynamic> _toMap(BusinessEntity b) => {
        'id': b.id,
        'userId': b.userId,
        'name': b.name,
        'category': b.category.name,
        'logoPath': b.logoPath,
        'contact': b.contact.toMap(),
        'socialLinks': b.socialLinks.toMap(),
      };

  BusinessEntity _fromMap(Map<String, dynamic> map) => BusinessEntity(
        id: map['id'],
        userId: map['userId'],
        name: map['name'],
        category: BusinessCategory.values.firstWhere(
          (c) => c.name == (map['category'] ?? map['type'] ?? 'autre'),
          orElse: () => BusinessCategory.autre,
        ),
        logoPath: map['logoPath'],
        contact: ContactInfo.fromMap(
            Map<String, dynamic>.from(map['contact'] ?? {})),
        socialLinks: SocialLinks.fromMap(
            Map<String, dynamic>.from(map['socialLinks'] ?? {})),
      );
}

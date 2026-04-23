import '../../core/constants/enums.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/template_entity.dart';
import '../../domain/repositories/template_repository.dart';

class HttpTemplateRepository implements TemplateRepository {
  final ApiClient _api;
  HttpTemplateRepository(this._api);

  @override
  Future<List<TemplateEntity>> getTemplates() async {
    final res = await _api.get('/templates', auth: false);
    return (res['templates'] as List<dynamic>)
        .map((t) => _fromMap(t as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TemplateEntity>> getTemplatesByType(WebsiteType type) async {
    final res = await _api.get('/templates?type=${type.name}', auth: false);
    return (res['templates'] as List<dynamic>)
        .map((t) => _fromMap(t as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TemplateEntity?> getTemplateById(String id) async {
    try {
      final res = await _api.get('/templates/$id', auth: false);
      return _fromMap(res['template'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  TemplateEntity _fromMap(Map<String, dynamic> m) => TemplateEntity(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String? ?? '',
        websiteType: WebsiteType.values.firstWhere(
          (t) => t.name == m['websiteType'],
          orElse: () => WebsiteType.showcase,
        ),
        defaultSections: (m['defaultSections'] as List<dynamic>? ?? [])
            .map((s) => SectionType.values.firstWhere(
                  (t) => t.name == s,
                  orElse: () => SectionType.hero,
                ))
            .toList(),
        previewColor: m['previewColor'] as String? ?? '#FF7900',
        thumbnailIcon: m['thumbnailIcon'] as String? ?? 'web',
      );
}

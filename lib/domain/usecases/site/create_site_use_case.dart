import 'package:uuid/uuid.dart';
import '../../../core/constants/enums.dart';
import '../../entities/site_entity.dart';
import '../../entities/template_entity.dart';
import '../../repositories/site_repository.dart';

class CreateSiteUseCase {
  final SiteRepository _repository;
  CreateSiteUseCase(this._repository);

  /// [sections] and [primaryColor], when provided, are persisted as-is
  /// instead of the template's untouched defaults — used by the fullscreen
  /// live template editor, which lets a merchant edit section text and
  /// reorder sections *before* the draft site is actually created, so the
  /// very first save already reflects their changes instead of the bare
  /// template.
  Future<SiteEntity> call({
    required String businessId,
    required TemplateEntity template,
    required WebsiteType websiteType,
    List<SiteSection>? sections,
    String? primaryColor,
  }) {
    const uuid = Uuid();
    final resolvedSections = sections ??
        template.defaultSections.asMap().entries.map((entry) {
          return SiteSection(
            id: uuid.v4(),
            type: entry.value,
            title: entry.value.label,
            order: entry.key,
          );
        }).toList();

    final site = SiteEntity(
      id: uuid.v4(),
      businessId: businessId,
      templateId: template.id,
      websiteType: websiteType,
      sections: resolvedSections,
      primaryColor: primaryColor,
      createdAt: DateTime.now(),
    );
    return _repository.createSite(site);
  }
}

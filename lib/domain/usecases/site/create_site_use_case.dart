import 'package:uuid/uuid.dart';
import '../../../core/constants/enums.dart';
import '../../entities/site_entity.dart';
import '../../entities/template_entity.dart';
import '../../repositories/site_repository.dart';

class CreateSiteUseCase {
  final SiteRepository _repository;
  CreateSiteUseCase(this._repository);

  Future<SiteEntity> call({
    required String businessId,
    required TemplateEntity template,
    required WebsiteType websiteType,
  }) {
    const uuid = Uuid();
    final sections = template.defaultSections.asMap().entries.map((entry) {
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
      sections: sections,
      createdAt: DateTime.now(),
    );
    return _repository.createSite(site);
  }
}

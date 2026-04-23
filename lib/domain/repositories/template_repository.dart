import '../../core/constants/enums.dart';
import '../entities/template_entity.dart';

/// Contract for template catalog operations.
abstract class TemplateRepository {
  Future<List<TemplateEntity>> getTemplates();
  Future<List<TemplateEntity>> getTemplatesByType(WebsiteType type);
  Future<TemplateEntity?> getTemplateById(String id);
}

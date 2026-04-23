import '../../../core/constants/enums.dart';
import '../../entities/template_entity.dart';
import '../../repositories/template_repository.dart';

class GetTemplatesByTypeUseCase {
  final TemplateRepository _repository;
  GetTemplatesByTypeUseCase(this._repository);

  Future<List<TemplateEntity>> call(WebsiteType type) =>
      _repository.getTemplatesByType(type);
}

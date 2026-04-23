import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/enums.dart';
import '../../../../domain/entities/template_entity.dart';
import '../../../../domain/usecases/template/get_templates_by_type_use_case.dart';
import 'template_state.dart';

/// Manages template selection flow.
class TemplateCubit extends Cubit<TemplateState> {
  final GetTemplatesByTypeUseCase _getTemplatesByType;

  TemplateCubit(this._getTemplatesByType) : super(const TemplateState());

  /// Initialize with a website type and load its templates immediately.
  Future<void> init(WebsiteType type) async {
    emit(state.copyWith(selectedWebsiteType: type));
    await loadTemplates(type);
  }

  /// Initialize with a website type and pre-select a template by ID.
  Future<void> initWithTemplate(WebsiteType type, String templateId) async {
    emit(state.copyWith(selectedWebsiteType: type));
    await loadTemplates(type);
    final match = state.templates.where((t) => t.id == templateId);
    if (match.isNotEmpty) {
      emit(state.copyWith(selectedTemplate: match.first));
    }
  }

  void selectWebsiteType(WebsiteType type) {
    emit(state.copyWith(selectedWebsiteType: type));
    loadTemplates(type);
  }

  Future<void> loadTemplates(WebsiteType type) async {
    emit(state.copyWith(status: TemplateStatus.loading));
    try {
      final templates = await _getTemplatesByType(type);
      emit(state.copyWith(
        status: TemplateStatus.loaded,
        templates: templates,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TemplateStatus.error,
        error: e.toString(),
      ));
    }
  }

  void selectTemplate(TemplateEntity template) {
    emit(state.copyWith(selectedTemplate: template));
  }
}

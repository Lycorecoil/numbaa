import 'package:equatable/equatable.dart';
import '../../../../core/constants/enums.dart';
import '../../../../domain/entities/template_entity.dart';

enum TemplateStatus { initial, loading, loaded, error }

class TemplateState extends Equatable {
  final TemplateStatus status;
  final WebsiteType? selectedWebsiteType;
  final List<TemplateEntity> templates;
  final TemplateEntity? selectedTemplate;
  final String? error;

  const TemplateState({
    this.status = TemplateStatus.initial,
    this.selectedWebsiteType,
    this.templates = const [],
    this.selectedTemplate,
    this.error,
  });

  TemplateState copyWith({
    TemplateStatus? status,
    WebsiteType? selectedWebsiteType,
    List<TemplateEntity>? templates,
    TemplateEntity? selectedTemplate,
    String? error,
  }) {
    return TemplateState(
      status: status ?? this.status,
      selectedWebsiteType: selectedWebsiteType ?? this.selectedWebsiteType,
      templates: templates ?? this.templates,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, selectedWebsiteType, templates, selectedTemplate, error];
}

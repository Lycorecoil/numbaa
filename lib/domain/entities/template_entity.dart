import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

/// A website template that users can pick.
class TemplateEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final WebsiteType websiteType;
  final List<SectionType> defaultSections;
  final String previewColor; // hex color for mock thumbnail
  final String thumbnailIcon; // icon name for mock thumbnail

  const TemplateEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.websiteType,
    required this.defaultSections,
    this.previewColor = '#FF7900',
    this.thumbnailIcon = 'web',
  });

  @override
  List<Object?> get props =>
      [id, name, description, websiteType, defaultSections];
}

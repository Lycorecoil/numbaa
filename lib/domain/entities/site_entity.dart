import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

/// A single section within a website.
class SiteSection extends Equatable {
  final String id;
  final SectionType type;
  final String title;
  final String content;
  final int order;

  const SiteSection({
    required this.id,
    required this.type,
    required this.title,
    this.content = '',
    required this.order,
  });

  SiteSection copyWith({
    String? id,
    SectionType? type,
    String? title,
    String? content,
    int? order,
  }) {
    return SiteSection(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [id, type, title, content, order];
}

/// A website project created by the user.
class SiteEntity extends Equatable {
  final String id;
  final String businessId;
  final String templateId;
  final WebsiteType websiteType;
  final List<SiteSection> sections;
  final SiteStatus status;
  final String? primaryColor;
  final DateTime createdAt;

  const SiteEntity({
    required this.id,
    required this.businessId,
    required this.templateId,
    required this.websiteType,
    this.sections = const [],
    this.status = SiteStatus.draft,
    this.primaryColor,
    required this.createdAt,
  });

  SiteEntity copyWith({
    String? id,
    String? businessId,
    String? templateId,
    WebsiteType? websiteType,
    List<SiteSection>? sections,
    SiteStatus? status,
    String? primaryColor,
    DateTime? createdAt,
  }) {
    return SiteEntity(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      templateId: templateId ?? this.templateId,
      websiteType: websiteType ?? this.websiteType,
      sections: sections ?? this.sections,
      status: status ?? this.status,
      primaryColor: primaryColor ?? this.primaryColor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        businessId,
        templateId,
        websiteType,
        sections,
        status,
        primaryColor,
        createdAt,
      ];
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/usecases/business/get_business_use_case.dart';
import 'package:uuid/uuid.dart';
import '../../../../domain/entities/site_entity.dart';
import '../../../../domain/usecases/site/create_site_use_case.dart';
import '../../../../domain/usecases/site/update_site_use_case.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/template_cubit.dart';
import '../cubits/template_state.dart';

/// Full preview of the selected template before creating (or changing) the site.
class TemplatePreviewScreen extends StatelessWidget {
  final String? siteId;
  const TemplatePreviewScreen({super.key, this.siteId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateCubit, TemplateState>(
      builder: (context, state) {
        final template = state.selectedTemplate;
        if (template == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Aucun template selectionne')),
          );
        }

        final color = _parseColor(template.previewColor);

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(template.name),
          ),
          body: Column(
            children: [
              // Mock full-page preview
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: template.defaultSections.map((section) {
                      return _MockSectionPreview(
                        sectionType: section,
                        accentColor: color,
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Bottom bar
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.divider),
                  ),
                ),
                child: NumbiaButton(
                  label: siteId != null
                      ? 'Appliquer ce template'
                      : 'Creer mon site avec ce template',
                  onPressed: () => siteId != null
                      ? _changeTemplate(context, state, siteId!)
                      : _createSite(context, state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeTemplate(BuildContext context, TemplateState state, String siteId) async {
    final template = state.selectedTemplate!;
    final websiteType = state.selectedWebsiteType!;
    final uuid = const Uuid();
    final sections = template.defaultSections
        .asMap()
        .entries
        .map((e) => SiteSection(
              id: uuid.v4(),
              type: e.value,
              title: e.value.label,
              content: '',
              order: e.key,
            ))
        .toList();

    final updated = await getIt<UpdateSiteUseCase>().call(SiteEntity(
      id: siteId,
      businessId: '',
      templateId: template.id,
      websiteType: websiteType,
      sections: sections,
      createdAt: DateTime.now(),
    ));
    if (context.mounted) {
      context.go('/editor/${updated.id}');
    }
  }

  Future<void> _createSite(BuildContext context, TemplateState state) async {
    final template = state.selectedTemplate!;
    final userId = context.read<AuthCubit>().state.user!.id;

    final business = await getIt<GetBusinessUseCase>().call(userId);
    if (business == null) return;

    final created = await getIt<CreateSiteUseCase>().call(
      businessId: business.id,
      template: template,
      websiteType: state.selectedWebsiteType!,
    );
    if (context.mounted) {
      context.go('/editor/${created.id}');
    }
  }

  Color _parseColor(String hex) {
    final code = hex.replaceAll('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }
}

/// Renders a mock visual block for a section type.
class _MockSectionPreview extends StatelessWidget {
  final SectionType sectionType;
  final Color accentColor;

  const _MockSectionPreview({
    required this.sectionType,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: _bgColor(),
        border: const Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sectionType.label,
              style: AppTypography.caption.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildContent(),
        ],
      ),
    );
  }

  Color _bgColor() {
    switch (sectionType) {
      case SectionType.hero:
        return accentColor.withValues(alpha: 0.05);
      case SectionType.footer:
        return AppColors.neutralDark;
      default:
        return AppColors.surface;
    }
  }

  Widget _buildContent() {
    switch (sectionType) {
      case SectionType.hero:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              width: 200,
              decoration: BoxDecoration(
                color: AppColors.neutralDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 14,
              width: 280,
              decoration: BoxDecoration(
                color: AppColors.neutralMid.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 36,
              width: 120,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ],
        );

      case SectionType.products:
        return Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.neutralLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    color: AppColors.neutralMid, size: 24),
              ),
            ),
          ),
        );

      case SectionType.gallery:
        return Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.neutralLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.image_outlined,
                    color: AppColors.neutralMid, size: 20),
              ),
            ),
          ),
        );

      case SectionType.footer:
        return Column(
          children: [
            Container(
              height: 10,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 8,
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );

      default:
        // Generic placeholder for other sections
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 14,
              width: 180,
              decoration: BoxDecoration(
                color: AppColors.neutralMid.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.neutralMid.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 10,
              width: 240,
              decoration: BoxDecoration(
                color: AppColors.neutralMid.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );
    }
  }
}

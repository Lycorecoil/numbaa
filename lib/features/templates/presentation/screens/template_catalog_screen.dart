import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/template_entity.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../../shared/widgets/numbia_card.dart';
import '../cubits/template_cubit.dart';
import '../cubits/template_state.dart';

/// Template catalog screen — browse and select a template.
class TemplateCatalogScreen extends StatelessWidget {
  const TemplateCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateCubit, TemplateState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Templates ${state.selectedWebsiteType?.label ?? ""}',
            ),
          ),
          body: state.status == TemplateStatus.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: state.templates.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final template = state.templates[index];
                          return _TemplateCard(
                            template: template,
                            isSelected:
                                state.selectedTemplate?.id == template.id,
                            onTap: () => context
                                .read<TemplateCubit>()
                                .selectTemplate(template),
                          );
                        },
                      ),
                    ),

                    // Bottom action
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: NumbiaButton(
                        label: 'Utiliser ce template',
                        onPressed: state.selectedTemplate != null
                            ? () => context.push(
                                '/template-preview?type=${state.selectedWebsiteType!.name}&templateId=${state.selectedTemplate!.id}')
                            : null,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TemplateEntity template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(template.previewColor);

    return NumbiaCard(
      selected: isSelected,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mock preview thumbnail
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIcon(template.thumbnailIcon),
                  size: 40,
                  color: color,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  template.name,
                  style: AppTypography.h3.copyWith(color: color),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.name, style: AppTypography.h3),
                const SizedBox(height: 4),
                Text(template.description, style: AppTypography.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: template.defaultSections
                      .map((s) => Chip(
                            label: Text(s.label,
                                style: AppTypography.caption),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: AppColors.neutralLight,
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final code = hex.replaceAll('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'business':
        return Icons.business;
      case 'storefront':
        return Icons.storefront;
      case 'language':
        return Icons.language;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.web;
    }
  }
}

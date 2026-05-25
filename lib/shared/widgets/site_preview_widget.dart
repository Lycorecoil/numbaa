import 'package:flutter/material.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/site_entity.dart';

/// Renders a full mock website preview using Flutter widgets.
/// Shared between PreviewScreen and TemplateCatalogScreen.
class SitePreviewWidget extends StatelessWidget {
  final SiteEntity site;
  final List<ProductEntity> products;

  const SitePreviewWidget({
    super.key,
    required this.site,
    required this.products,
  });

  Color get _accent {
    final hex = site.primaryColor;
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in site.sections) _buildSection(section),
        ],
      ),
    );
  }

  Widget _buildSection(SiteSection section) {
    switch (section.type) {
      case SectionType.hero:
        final isEcommerce = site.websiteType == WebsiteType.ecommerce;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          color: isEcommerce ? _accent : _accent.withValues(alpha: 0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                section.title.isNotEmpty ? section.title : 'Bienvenue',
                style: AppTypography.h1.copyWith(
                  color: isEcommerce ? Colors.white : _accent,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                section.content.isNotEmpty
                    ? section.content
                    : 'Decouvrez nos services professionnels.',
                style: AppTypography.body.copyWith(
                  color: isEcommerce
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.neutralMid,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isEcommerce ? Colors.white : _accent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text('Nous contacter',
                    style: AppTypography.button.copyWith(
                      color: isEcommerce ? _accent : Colors.white,
                    )),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );

      case SectionType.about:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.title, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              Text(
                section.content.isNotEmpty
                    ? section.content
                    : 'Nous sommes une entreprise dediee a la qualite et au service client.',
                style: AppTypography.body,
              ),
            ],
          ),
        );

      case SectionType.services:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: AppColors.neutralLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.title, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _serviceItem('Service 1', Icons.star_outline),
                  const SizedBox(width: AppSpacing.sm),
                  _serviceItem('Service 2', Icons.star_outline),
                  const SizedBox(width: AppSpacing.sm),
                  _serviceItem('Service 3', Icons.star_outline),
                ],
              ),
            ],
          ),
        );

      case SectionType.products:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.title, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.md),
              if (products.isEmpty)
                Text('Aucun produit ajoute', style: AppTypography.bodySmall)
              else
                ...products.take(4).map((p) => Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            color: AppColors.neutralLight,
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.neutralMid, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: AppTypography.body),
                                Text(
                                    '${p.price.toStringAsFixed(0)} FCFA',
                                    style: AppTypography.bodySmall
                                        .copyWith(color: _accent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        );

      case SectionType.contact:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: AppColors.neutralLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.title, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.md),
              _contactRow(Icons.phone_outlined, '+226 70 00 00 00'),
              _contactRow(Icons.email_outlined, 'contact@monentreprise.com'),
              _contactRow(Icons.chat_outlined, 'WhatsApp'),
            ],
          ),
        );

      case SectionType.gallery:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.title, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Container(
                      height: 80,
                      margin:
                          EdgeInsets.only(right: i < 2 ? AppSpacing.sm : 0),
                      decoration: BoxDecoration(
                        color: AppColors.neutralLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.neutralMid),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case SectionType.testimonials:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.title, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.neutralLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Column(
                  children: [
                    Icon(Icons.format_quote, color: _accent),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      '"Excellent service, je recommande vivement !"',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('— Fatima K., cliente satisfaite',
                        style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
        );

      case SectionType.footer:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: AppColors.neutralDark,
          child: Column(
            children: [
              Text(
                section.title,
                style:
                    AppTypography.bodySmall.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Cree avec NUMBAA',
                style: AppTypography.caption.copyWith(color: Colors.white38),
              ),
            ],
          ),
        );
    }
  }

  Widget _serviceItem(String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: _accent),
            const SizedBox(height: AppSpacing.xs),
            Text(label,
                style: AppTypography.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _accent),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.body),
        ],
      ),
    );
  }
}

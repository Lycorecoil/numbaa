import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../domain/entities/site_entity.dart';
import '../../../../domain/entities/template_entity.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../../shared/widgets/site_preview_widget.dart';
import '../cubits/template_cubit.dart';
import '../cubits/template_state.dart';

class TemplateCatalogScreen extends StatefulWidget {
  final String? siteId;
  const TemplateCatalogScreen({super.key, this.siteId});

  @override
  State<TemplateCatalogScreen> createState() => _TemplateCatalogScreenState();
}

class _TemplateCatalogScreenState extends State<TemplateCatalogScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateCubit, TemplateState>(
      builder: (context, state) {
        final templates = state.templates;
        return Scaffold(
          backgroundColor: AppColors.neutralDark,
          appBar: AppBar(
            backgroundColor: AppColors.neutralDark,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Choisissez votre modele'),
          ),
          body: state.status == TemplateStatus.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : templates.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun modele disponible',
                        style: AppTypography.body
                            .copyWith(color: Colors.white54),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: templates.length,
                            onPageChanged: (i) {
                              setState(() => _currentPage = i);
                              context
                                  .read<TemplateCubit>()
                                  .selectTemplate(templates[i]);
                            },
                            itemBuilder: (context, index) {
                              final template = templates[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: SitePreviewWidget(
                                    site: _buildMockSite(template),
                                    products: template.websiteType ==
                                            WebsiteType.ecommerce
                                        ? _mockProducts
                                        : const [],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          color: AppColors.neutralDark,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  templates.length,
                                  (i) => AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width: i == _currentPage ? 20 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: i == _currentPage
                                          ? AppColors.primary
                                          : Colors.white38,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                templates[_currentPage].name,
                                style: AppTypography.h3
                                    .copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              NumbiaButton(
                                label: 'Choisir ce modele',
                                onPressed: () {
                                  final template = templates[_currentPage];
                                  context.push(
                                    '/template-preview?type=${state.selectedWebsiteType!.name}&templateId=${template.id}${widget.siteId != null ? '&siteId=${widget.siteId}' : ''}',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  SiteEntity _buildMockSite(TemplateEntity template) {
    final isEcommerce = template.websiteType == WebsiteType.ecommerce;
    final sections =
        template.defaultSections.asMap().entries.map((entry) {
      final i = entry.key;
      final type = entry.value;
      return SiteSection(
        id: 'mock_${template.id}_$i',
        type: type,
        title: _sectionTitle(type, isEcommerce),
        content: _sectionContent(type, isEcommerce),
        order: i,
      );
    }).toList();

    return SiteEntity(
      id: 'mock_${template.id}',
      businessId: 'mock',
      templateId: template.id,
      websiteType: template.websiteType,
      sections: sections,
      primaryColor: template.previewColor,
      createdAt: DateTime(2025),
    );
  }

  String _sectionTitle(SectionType type, bool isEcommerce) {
    switch (type) {
      case SectionType.hero:
        return isEcommerce ? 'Boutique Aminata' : 'Atelier Kone';
      case SectionType.about:
        return 'A Propos';
      case SectionType.services:
        return 'Nos Services';
      case SectionType.products:
        return 'Nos Produits';
      case SectionType.contact:
        return 'Nous Contacter';
      case SectionType.gallery:
        return 'Notre Galerie';
      case SectionType.testimonials:
        return 'Avis Clients';
      case SectionType.footer:
        return isEcommerce
            ? '© 2025 Boutique Aminata'
            : '© 2025 Atelier Kone';
    }
  }

  String _sectionContent(SectionType type, bool isEcommerce) {
    switch (type) {
      case SectionType.hero:
        return isEcommerce
            ? 'Vetements, bijoux et accessoires. Livraison rapide a Ouagadougou.'
            : 'Meubles sur mesure, artisan depuis 2010. Qualite et savoir-faire.';
      case SectionType.about:
        return isEcommerce
            ? 'Nous proposons les plus belles tenues africaines et modernes depuis 2018.'
            : 'Notre atelier fabrique des meubles de qualite sur mesure pour votre interieur.';
      default:
        return '';
    }
  }

  static const List<ProductEntity> _mockProducts = [
    ProductEntity(
      id: 'mock_p1',
      siteId: 'mock',
      name: 'Robe wax premium',
      price: 15000,
      category: 'Vetements',
    ),
    ProductEntity(
      id: 'mock_p2',
      siteId: 'mock',
      name: 'Sac cuir artisanal',
      price: 8500,
      category: 'Accessoires',
    ),
    ProductEntity(
      id: 'mock_p3',
      siteId: 'mock',
      name: 'Collier perles',
      price: 3500,
      category: 'Bijoux',
    ),
  ];
}

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
import '../../../../shared/widgets/card_swipe_stack.dart';
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
  int _currentPage = 0;
  final _stackKey = GlobalKey<CardSwipeStackState>();

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
              tooltip: 'Retour',
              onPressed: () => context.pop(),
            ),
            title: const Text('Choisissez votre modele'),
          ),
          body: state.status == TemplateStatus.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : state.status == TemplateStatus.error
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 48),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Impossible de charger les modeles. Verifiez votre connexion.',
                              style: AppTypography.body
                                  .copyWith(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            NumbiaButton(
                              label: 'Reessayer',
                              onPressed: () => context
                                  .read<TemplateCubit>()
                                  .loadTemplates(state.selectedWebsiteType ??
                                      WebsiteType.showcase),
                            ),
                          ],
                        ),
                      ),
                    )
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            child: CardSwipeStack(
                              key: _stackKey,
                              itemCount: templates.length,
                              initialIndex: _currentPage,
                              onIndexChanged: (i) {
                                setState(() => _currentPage = i);
                                context
                                    .read<TemplateCubit>()
                                    .selectTemplate(templates[i]);
                              },
                              onCardTap: (i) => _openFullscreenEditor(
                                context,
                                templates[i],
                                state.selectedWebsiteType!,
                              ),
                              cardBuilder: (context, index) {
                                final template = templates[index];
                                return _TemplatePosterCard(
                                  heroTag: templateHeroTag(template.id),
                                  // Purely a visual thumbnail here: swallow all
                                  // pointer events inside it (the preview's own
                                  // product carousel included) so a swipe never
                                  // gets stolen from the outer CardSwipeStack —
                                  // only that outer stack should ever move on
                                  // this screen.
                                  child: IgnorePointer(
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
                                  (i) => GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () =>
                                        _stackKey.currentState?.goTo(i),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: AppSpacing.sm),
                                      child: AnimatedContainer(
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
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                templates[_currentPage].name,
                                style: AppTypography.h3
                                    .copyWith(color: Colors.white),
                              ),
                              if (templates[_currentPage]
                                  .description
                                  .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  templates[_currentPage].description,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall
                                      .copyWith(color: Colors.white54),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              NumbiaButton(
                                label: 'Choisir ce modele',
                                onPressed: () => _openFullscreenEditor(
                                  context,
                                  templates[_currentPage],
                                  state.selectedWebsiteType!,
                                ),
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

  /// Pushes the fullscreen live template editor. The tapped/selected
  /// template is passed via `extra` (not just the `templateId` query
  /// param) so the destination screen can render synchronously on its
  /// first frame — required for the Hero "card expands to fullscreen"
  /// transition to actually play.
  void _openFullscreenEditor(
    BuildContext context,
    TemplateEntity template,
    WebsiteType websiteType,
  ) {
    context.push(
      '/template-preview?type=${websiteType.name}&templateId=${template.id}'
      '${widget.siteId != null ? '&siteId=${widget.siteId}' : ''}',
      extra: template,
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

/// Hero tag shared with the fullscreen live editor (see
/// TemplatePreviewScreen) so tapping a card grows it into that screen
/// instead of a plain page transition.
String templateHeroTag(String templateId) => 'template-poster-$templateId';

/// Wraps a template preview in a floating "poster" shell — deep shadow,
/// generous rounded corners — so it reads as a physical card in the swipe
/// stack rather than a plain rectangle of content.
///
/// The shadow/rounded-corner "frame" deliberately sits *outside* the [Hero]
/// so only the plain, unradiused preview content is what actually flies
/// during the transition — Hero doesn't interpolate decoration (radius,
/// shadow) over the flight, so animating the frame too would make the
/// corners "pop" square mid-flight. Keeping the frame out of the Hero
/// avoids that glitch for free: it simply stays behind as the pushed route
/// covers it.
class _TemplatePosterCard extends StatelessWidget {
  final Widget child;
  final String heroTag;
  const _TemplatePosterCard({required this.child, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Hero(tag: heroTag, child: child),
    );
  }
}

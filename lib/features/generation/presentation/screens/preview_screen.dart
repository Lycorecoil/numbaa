import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/site_entity.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../site_editor/presentation/cubits/editor_cubit.dart';
import '../../../site_editor/presentation/cubits/editor_state.dart';

/// Simulated website preview rendered in Flutter (no WebView dependency).
class PreviewScreen extends StatefulWidget {
  final String siteId;

  const PreviewScreen({super.key, required this.siteId});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _isMobileView = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorCubit, EditorState>(
      builder: (context, state) {
        final site = state.site;

        return Scaffold(
          backgroundColor: AppColors.neutralDark,
          appBar: AppBar(
            backgroundColor: AppColors.neutralDark,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Apercu'),
            actions: [
              // Toggle mobile / desktop
              IconButton(
                icon: Icon(_isMobileView
                    ? Icons.desktop_windows_outlined
                    : Icons.smartphone_outlined),
                onPressed: () =>
                    setState(() => _isMobileView = !_isMobileView),
                tooltip: _isMobileView ? 'Vue desktop' : 'Vue mobile',
              ),
            ],
          ),
          body: Column(
            children: [
              // Viewport label
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  _isMobileView ? 'Mobile (375px)' : 'Desktop (1024px)',
                  style: AppTypography.caption.copyWith(color: Colors.white54),
                ),
              ),

              // Preview area
              Expanded(
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isMobileView ? 375 : double.infinity,
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: site != null
                        ? _WebsitePreview(
                            site: site,
                            products: state.products,
                          )
                        : const Center(child: Text('Aucun contenu')),
                  ),
                ),
              ),

              // Publish button
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: NumbiaButton(
                  label: 'Publier le site',
                  icon: Icons.rocket_launch_outlined,
                  onPressed: () => context.push('/publish/${widget.siteId}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Renders a mock website preview using Flutter widgets.
class _WebsitePreview extends StatelessWidget {
  final SiteEntity site;
  final List products;

  const _WebsitePreview({required this.site, required this.products});

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
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          color: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                section.title.isNotEmpty ? section.title : 'Bienvenue',
                style: AppTypography.h1.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                section.content.isNotEmpty
                    ? section.content
                    : 'Decouvrez nos services professionnels.',
                style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text('Nous contacter',
                    style: AppTypography.button
                        .copyWith(color: AppColors.primary)),
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
                Text('Aucun produit ajoute',
                    style: AppTypography.bodySmall)
              else
                ...products.take(4).map((p) => Container(
                      margin:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm),
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: AppTypography.body),
                                Text('${p.price.toStringAsFixed(0)} FCFA',
                                    style: AppTypography.bodySmall
                                        .copyWith(
                                            color: AppColors.primary)),
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
              _contactRow(Icons.phone_outlined, 'Telephone'),
              _contactRow(Icons.email_outlined, 'Email'),
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
                      margin: EdgeInsets.only(
                          right: i < 2 ? AppSpacing.sm : 0),
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
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.format_quote,
                        color: AppColors.primary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '"Excellent service, je recommande vivement !"',
                      style: AppTypography.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('— Client satisfait',
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
                'Cree avec NUMBIA par Orange',
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
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTypography.caption,
                textAlign: TextAlign.center),
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
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.body),
        ],
      ),
    );
  }
}

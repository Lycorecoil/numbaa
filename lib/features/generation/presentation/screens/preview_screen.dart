import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../../shared/widgets/site_preview_widget.dart';
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
        final isLoading = state.status == EditorStatus.loading;
        final hasError = state.status == EditorStatus.error && site == null;

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
            title: const Text('Apercu'),
            actions: [
              // Toggle mobile / desktop
              if (!isLoading && !hasError)
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      _isMobileView
                          ? Icons.desktop_windows_outlined
                          : Icons.smartphone_outlined,
                      key: ValueKey(_isMobileView),
                    ),
                  ),
                  onPressed: () =>
                      setState(() => _isMobileView = !_isMobileView),
                  tooltip: _isMobileView ? 'Vue desktop' : 'Vue mobile',
                ),
            ],
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : hasError
                  ? EmptyState(
                      icon: Icons.error_outline,
                      title: 'Impossible de charger l\'apercu',
                      subtitle: state.error ?? 'Une erreur est survenue.',
                      actionLabel: 'Retour au tableau de bord',
                      onAction: () => context.go('/dashboard'),
                    )
                  : Column(
                      children: [
                        // Viewport label
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isMobileView
                                  ? 'Mobile (375px)'
                                  : 'Desktop (1024px)',
                              style: AppTypography.caption
                                  .copyWith(color: Colors.white70),
                            ),
                          ),
                        ),

                        // Preview area
                        Expanded(
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              width: _isMobileView ? 375 : double.infinity,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: site != null
                                  ? SitePreviewWidget(
                                      site: site,
                                      products: state.products,
                                      business: state.business,
                                    )
                                  : const Center(
                                      child: Text('Aucun contenu')),
                            ),
                          ),
                        ),

                        // Publish button
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: NumbiaButton(
                            label: 'Publier le site',
                            icon: Icons.rocket_launch_outlined,
                            onPressed: () =>
                                context.push('/publish/${widget.siteId}'),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}


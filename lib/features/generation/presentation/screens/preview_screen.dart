import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
                        ? SitePreviewWidget(
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


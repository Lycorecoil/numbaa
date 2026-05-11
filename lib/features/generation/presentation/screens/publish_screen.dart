import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/usecases/site/publish_site_use_case.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../site_editor/presentation/cubits/editor_cubit.dart';
import '../../../site_editor/presentation/cubits/editor_state.dart';

/// Mock publish flow — simulates deploying to Vercel.
class PublishScreen extends StatefulWidget {
  final String siteId;

  const PublishScreen({super.key, required this.siteId});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

enum _PublishStage { summary, publishing, success, error }

class _PublishScreenState extends State<PublishScreen> {
  _PublishStage _stage = _PublishStage.summary;
  String? _error;
  String? _publishedUrl;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorCubit, EditorState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Publication'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _buildContent(context, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, EditorState state) {
    switch (_stage) {
      case _PublishStage.summary:
        return _buildSummary(context, state);
      case _PublishStage.publishing:
        return _buildPublishing();
      case _PublishStage.success:
        return _buildSuccess(context);
      case _PublishStage.error:
        return _buildError(context);
    }
  }

  Widget _buildSummary(BuildContext context, EditorState state) {
    final site = state.site;
    final sectionCount = site?.sections.length ?? 0;
    final productCount = state.products.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pret a publier ?', style: AppTypography.h1),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Verifiez les informations avant de publier votre site.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Summary card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.neutralLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            children: [
              _summaryRow('Type de site', site?.websiteType.label ?? '—'),
              const Divider(height: AppSpacing.lg),
              _summaryRow('Sections', '$sectionCount'),
              if (productCount > 0) ...[
                const Divider(height: AppSpacing.lg),
                _summaryRow('Produits', '$productCount'),
              ],
              const Divider(height: AppSpacing.lg),
              _summaryRow('Statut', site?.status.label ?? '—'),
            ],
          ),
        ),
        const Spacer(),

        NumbiaButton(
          label: 'Publier mon site',
          icon: Icons.rocket_launch_outlined,
          onPressed: () => _publish(context),
        ),
      ],
    );
  }

  Widget _buildPublishing() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Publication en cours...', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Generation et deploiement de votre site',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 72),
          const SizedBox(height: AppSpacing.lg),
          Text('Site publie !', style: AppTypography.h1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Votre site est maintenant en ligne.',
            style: AppTypography.bodySmall,
          ),
          if (_publishedUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lien copie !'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _publishedUrl!,
                        style: AppTypography.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.copy_outlined,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          NumbiaButton(
            label: 'Retour au tableau de bord',
            onPressed: () => context.go('/dashboard'),
          ),
          const SizedBox(height: AppSpacing.sm),
          NumbiaButton(
            label: 'Modifier le site',
            variant: NumbiaButtonVariant.secondary,
            onPressed: () => context.go('/editor/${widget.siteId}'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 64),
          const SizedBox(height: AppSpacing.lg),
          Text('Erreur de publication', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error ?? 'Une erreur est survenue.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          NumbiaButton(
            label: 'Reessayer',
            onPressed: () => _publish(context),
          ),
        ],
      ),
    );
  }

  Future<void> _publish(BuildContext context) async {
    final cubit = context.read<EditorCubit>();
    setState(() => _stage = _PublishStage.publishing);

    try {
      final updatedSite = await getIt<PublishSiteUseCase>().call(widget.siteId);

      if (mounted) {
        cubit.loadSiteEntity(updatedSite);
        setState(() {
          _stage = _PublishStage.success;
          _publishedUrl = updatedSite.publishedUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stage = _PublishStage.error;
          _error = e.toString();
        });
      }
    }
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body),
        Text(value,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

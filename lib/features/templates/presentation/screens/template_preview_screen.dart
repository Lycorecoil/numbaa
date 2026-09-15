import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/template_entity.dart';
import '../../../../domain/usecases/business/get_business_use_case.dart';
import '../../../../domain/usecases/site/get_site_use_case.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../../shared/widgets/site_preview_widget.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../site_editor/presentation/cubits/editor_cubit.dart';
import '../../../site_editor/presentation/cubits/editor_state.dart';
import '../cubits/template_cubit.dart';
import '../cubits/template_state.dart';
import 'template_catalog_screen.dart' show templateHeroTag;

/// Fullscreen "live" template editor — opened by tapping a card in the
/// template catalog (grows into this screen via a [Hero] transition tagged
/// with [templateHeroTag]). Shows the real [SitePreviewWidget] rendering
/// instead of a static mock, and lets the merchant edit it directly: tap
/// any title/paragraph to edit it in place, long-press a section to drag
/// it to a new position.
///
/// No site is created just from opening this screen. The very first real
/// edit (text change or reorder) transparently creates the draft site
/// (status [SiteStatus.draft]) via [EditorCubit.beginFromTemplate] /
/// [EditorCubit.editSectionInline]; further edits autosave with a short
/// debounce. "Terminer" always finalizes the selection (creating the site
/// even if nothing was edited, like the old "Choisir ce modele" action)
/// and continues to the classic editor for detailed work (products, etc.).
class TemplatePreviewScreen extends StatefulWidget {
  final String? siteId;
  const TemplatePreviewScreen({super.key, this.siteId});

  @override
  State<TemplatePreviewScreen> createState() => _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends State<TemplatePreviewScreen> {
  bool _initiated = false;

  @override
  void initState() {
    super.initState();
    // Covers the common case: the catalog passed the template via `extra`,
    // so TemplateCubit.selectDirect already ran synchronously before this
    // widget even built — nothing to wait for.
    _maybeStart(context.read<TemplateCubit>().state);
  }

  void _maybeStart(TemplateState templateState) {
    if (_initiated) return;
    final template = templateState.selectedTemplate;
    if (template == null) return;
    _initiated = true;
    _startLiveEditing(
      template,
      templateState.selectedWebsiteType ?? WebsiteType.showcase,
    );
  }

  Future<void> _startLiveEditing(
    TemplateEntity template,
    WebsiteType websiteType,
  ) async {
    final editorCubit = context.read<EditorCubit>();
    final userId = context.read<AuthCubit>().state.user?.id;

    if (widget.siteId == null) {
      // Brand-new selection: render immediately from the template alone
      // (no network dependency), then resolve the business id lazily —
      // the first edit awaits it if it hasn't arrived yet (see
      // EditorCubit.setOriginBusinessId / _persistDraftFirstTime).
      editorCubit.beginFromTemplate(template: template, websiteType: websiteType);
      if (userId == null) return;
      try {
        final business = await getIt<GetBusinessUseCase>().call(userId);
        if (!mounted || business == null) return;
        editorCubit.setBusiness(business);
        editorCubit.setOriginBusinessId(business.id);
      } catch (_) {
        // Swallow: surfaced only if/when an edit actually needs it and the
        // business id still hasn't resolved.
      }
      return;
    }

    // Changing template on an existing site (or reopening this screen on
    // one) needs the real site from the network before there's anything
    // to show, so this path doesn't get the synchronous first frame the
    // Hero flight needs — it falls back to a plain loading state, which is
    // an accepted scope trade-off for this secondary flow.
    if (userId == null) {
      editorCubit.setError('Utilisateur non connecte');
      return;
    }
    try {
      final business = await getIt<GetBusinessUseCase>().call(userId);
      if (!mounted) return;
      if (business == null) {
        editorCubit.setError('Business introuvable');
        return;
      }
      editorCubit.setBusiness(business);
      final site = await getIt<GetSiteUseCase>().call(business.id);
      if (!mounted) return;
      if (site == null) {
        editorCubit.setError('Site introuvable');
        return;
      }
      editorCubit.beginFromExistingSite(
        site,
        newTemplate: template,
        newWebsiteType: websiteType,
      );
    } catch (_) {
      if (mounted) {
        editorCubit.setError(
          'Impossible de charger le site. Verifiez votre connexion et reessayez.',
        );
      }
    }
  }

  /// Back arrow / hardware back: persist a pending edit if there is one,
  /// but never create a draft just because the merchant opened and closed
  /// this screen without touching anything.
  Future<void> _leaveWithAutosave(BuildContext context) async {
    await context.read<EditorCubit>().finishLiveEditing();
    if (context.mounted) context.pop();
  }

  /// "Terminer": always finalizes the selection, then hands off to the
  /// classic editor for detailed work (products, full section list) — the
  /// same destination the old eager "Choisir ce modele" / "Appliquer ce
  /// template" actions already used.
  Future<void> _finishAndContinue(BuildContext context) async {
    final cubit = context.read<EditorCubit>();
    final site = await cubit.commitSelection();
    if (!context.mounted) return;
    if (cubit.state.status == EditorStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cubit.state.error ??
              'Impossible d\'enregistrer. Verifiez votre connexion.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.go('/editor/${site.id}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TemplateCubit, TemplateState>(
      listener: (context, templateState) => _maybeStart(templateState),
      child: BlocBuilder<EditorCubit, EditorState>(
        builder: (context, editorState) {
          final template = context.watch<TemplateCubit>().state.selectedTemplate;
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _leaveWithAutosave(context);
            },
            child: Scaffold(
              backgroundColor: AppColors.surface,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Retour',
                  onPressed: () => _leaveWithAutosave(context),
                ),
                title: Text(template?.name ?? 'Modele'),
                actions: [
                  if (editorState.status == EditorStatus.saving)
                    const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.lg),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              body: _buildBody(context, editorState, template),
              bottomNavigationBar: editorState.site == null
                  ? null
                  : _buildBottomBar(context, editorState),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    EditorState state,
    TemplateEntity? template,
  ) {
    if (state.site == null) {
      if (state.status == EditorStatus.error) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.error ?? 'Une erreur est survenue.',
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                NumbiaButton(
                  label: 'Retour',
                  variant: NumbiaButtonVariant.secondary,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final heroTag = template != null ? templateHeroTag(template.id) : null;
    final preview = SitePreviewWidget(
      site: state.site!,
      products: state.products,
      business: state.business,
      editable: true,
      onSectionChanged: (updated) =>
          context.read<EditorCubit>().editSectionInline(updated),
      onSectionReorder: (oldIndex, newIndex) => context
          .read<EditorCubit>()
          .reorderSectionsInline(oldIndex, newIndex),
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Touchez un texte pour le modifier. Maintenez une '
                  'section pour la deplacer.',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.primaryDark),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: heroTag != null
              ? Hero(tag: heroTag, child: preview)
              : preview,
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, EditorState state) {
    final isBusy = state.status == EditorStatus.saving;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: NumbiaButton(
        label: 'Terminer',
        icon: Icons.check_circle_outline,
        isLoading: isBusy,
        onPressed: isBusy ? null : () => _finishAndContinue(context),
      ),
    );
  }
}

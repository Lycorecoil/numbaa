import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/site_entity.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../../shared/widgets/numbia_card.dart';
import '../cubits/editor_cubit.dart';
import '../cubits/editor_state.dart';

/// Main editor screen — list of sections with reorder, edit, add.
class EditorScreen extends StatelessWidget {
  final String siteId;

  const EditorScreen({super.key, required this.siteId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorCubit, EditorState>(
      builder: (context, state) {
        if (state.status == EditorStatus.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Editeur')),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final site = state.site;
        if (site == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Editeur')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.error ?? 'Site introuvable',
                      style: AppTypography.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    NumbiaButton(
                      label: 'Retour au tableau de bord',
                      variant: NumbiaButtonVariant.secondary,
                      onPressed: () => context.go('/dashboard'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final isSaving = state.status == EditorStatus.saving;

        return PopScope(
          // Intercept the hardware/gesture back navigation too, so edits
          // are saved the same way whether the user taps the app bar
          // arrow or swipes/presses back.
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _saveAndLeave(context);
          },
          child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Retour',
              onPressed: () => _saveAndLeave(context),
            ),
            title: const Text('Editeur de site'),
            actions: [
              IconButton(
                icon: const Icon(Icons.style_outlined),
                tooltip: 'Changer de template',
                onPressed: () => context.push('/website-type?siteId=$siteId'),
              ),
              IconButton(
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                tooltip: 'Sauvegarder',
                onPressed: isSaving ? null : () => _saveWithFeedback(context),
              ),
            ],
          ),
          body: Column(
            children: [
              if (site.sections.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_vert,
                          size: 14, color: AppColors.neutralMid),
                      const SizedBox(width: 4),
                      Text(
                        'Maintenez une section pour la déplacer',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.neutralMid),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: site.sections.length,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (_, __) => Material(
                        elevation: 8,
                        shadowColor: AppColors.primary.withValues(alpha: 0.25),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        child: Opacity(opacity: 0.95, child: child),
                      ),
                    );
                  },
                  onReorderItem: (oldIndex, newIndex) {
                    context
                        .read<EditorCubit>()
                        .reorderSections(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final section = site.sections[index];
                    return _SectionTile(
                      key: ValueKey(section.id),
                      section: section,
                      onEdit: () => _editSection(context, section),
                      onDelete: () => _confirmDeleteSection(context, section),
                    );
                  },
                ),
              ),

              // Products shortcut for e-commerce
              if (site.websiteType == WebsiteType.ecommerce)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  child: NumbiaButton(
                    label: 'Gerer les produits (${state.products.length})',
                    variant: NumbiaButtonVariant.secondary,
                    icon: Icons.inventory_2_outlined,
                    onPressed: () => context.push('/editor/$siteId/products'),
                  ),
                ),

              const SizedBox(height: AppSpacing.sm),

              // Bottom actions
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: NumbiaButton(
                        label: 'Ajouter',
                        variant: NumbiaButtonVariant.secondary,
                        icon: Icons.add,
                        onPressed: () => _showAddSectionSheet(context, site),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: NumbiaButton(
                        label: 'Apercu',
                        icon: Icons.visibility_outlined,
                        onPressed: () => _saveThenPreview(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  /// Persists pending edits before leaving the editor so changes made via
  /// drag-reorder / add / edit sections are never silently lost.
  Future<void> _saveAndLeave(BuildContext context) async {
    await context.read<EditorCubit>().saveSite();
    if (context.mounted) context.pop();
  }

  /// Saves and shows a snackbar that reflects the *actual* outcome, instead
  /// of always claiming success regardless of what happened.
  Future<void> _saveWithFeedback(BuildContext context) async {
    final cubit = context.read<EditorCubit>();
    await cubit.saveSite();
    if (!context.mounted) return;
    final failed = cubit.state.status == EditorStatus.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failed
            ? (cubit.state.error ?? 'Erreur lors de la sauvegarde')
            : 'Site sauvegarde'),
        backgroundColor: failed ? AppColors.error : AppColors.success,
      ),
    );
  }

  /// Saves before opening the preview, and blocks navigation on failure so
  /// the merchant never previews content that differs from what would
  /// actually be published.
  Future<void> _saveThenPreview(BuildContext context) async {
    final cubit = context.read<EditorCubit>();
    await cubit.saveSite();
    if (!context.mounted) return;
    if (cubit.state.status == EditorStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              cubit.state.error ?? 'Erreur lors de la sauvegarde. Reessayez.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.push('/preview/$siteId');
  }

  Future<void> _confirmDeleteSection(
      BuildContext context, SiteSection section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette section ?'),
        content: Text(
          '"${section.title.isNotEmpty ? section.title : section.type.label}" '
          'sera retiree de votre site. Cette action est irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<EditorCubit>().removeSection(section.id);
    }
  }

  void _editSection(BuildContext context, SiteSection section) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (_) => _SectionEditSheet(
        section: section,
        onSave: (updated) {
          context.read<EditorCubit>().updateSection(updated);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showAddSectionSheet(BuildContext context, SiteEntity site) {
    // A merchant tapping around without understanding "sections" could
    // otherwise add a second Hero or a second Footer, producing a visibly
    // broken page (two banners, two footers stacked). Mark types already on
    // the site as such and disable re-adding them, pointing back to the
    // existing one instead.
    final existingTypes = site.sections.map((s) => s.type).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ajouter une section', style: AppTypography.h2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                children: SectionType.values.map((type) {
                  final alreadyAdded = existingTypes.contains(type);
                  return ListTile(
                    enabled: !alreadyAdded,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: alreadyAdded
                            ? AppColors.neutralLight
                            : AppColors.primaryLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        _iconForSection(type),
                        size: 20,
                        color: alreadyAdded
                            ? AppColors.neutralMid
                            : AppColors.primary,
                      ),
                    ),
                    title: Text(
                      type.label,
                      style: AppTypography.body.copyWith(
                        color: alreadyAdded ? AppColors.neutralMid : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: alreadyAdded
                        ? Text('Deja ajoutee — modifiez-la dans la liste',
                            style: AppTypography.caption)
                        : null,
                    trailing: alreadyAdded
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.neutralLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check,
                                    size: 14, color: AppColors.neutralMid),
                                const SizedBox(width: 4),
                                Text(
                                  'Ajoutee',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.neutralMid,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Icon(Icons.add_circle_outline,
                            size: 20, color: AppColors.primary),
                    onTap: alreadyAdded
                        ? null
                        : () {
                            context.read<EditorCubit>().addSection(type);
                            Navigator.of(context).pop();
                          },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForSection(SectionType type) {
    switch (type) {
      case SectionType.hero:
        return Icons.flag_outlined;
      case SectionType.about:
        return Icons.info_outlined;
      case SectionType.services:
        return Icons.miscellaneous_services_outlined;
      case SectionType.gallery:
        return Icons.photo_library_outlined;
      case SectionType.products:
        return Icons.shopping_bag_outlined;
      case SectionType.contact:
        return Icons.contact_mail_outlined;
      case SectionType.testimonials:
        return Icons.format_quote_outlined;
      case SectionType.footer:
        return Icons.call_to_action_outlined;
    }
  }
}

// --- Section tile in the reorderable list ---
class _SectionTile extends StatelessWidget {
  final SiteSection section;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SectionTile({
    super.key,
    required this.section,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _iconForType(SectionType type) {
    switch (type) {
      case SectionType.hero:
        return Icons.flag_outlined;
      case SectionType.about:
        return Icons.info_outlined;
      case SectionType.services:
        return Icons.miscellaneous_services_outlined;
      case SectionType.gallery:
        return Icons.photo_library_outlined;
      case SectionType.products:
        return Icons.shopping_bag_outlined;
      case SectionType.contact:
        return Icons.contact_mail_outlined;
      case SectionType.testimonials:
        return Icons.format_quote_outlined;
      case SectionType.footer:
        return Icons.call_to_action_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: NumbiaCard(
        onTap: onEdit,
        child: Row(
          children: [
            Icon(Icons.drag_handle, color: AppColors.neutralMid, size: 22),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(_iconForType(section.type),
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title.isNotEmpty
                        ? section.title
                        : section.type.label,
                    style: AppTypography.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(section.type.label, style: AppTypography.caption),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Modifier la section',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.error),
              tooltip: 'Supprimer la section',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Section edit bottom sheet ---
class _SectionEditSheet extends StatefulWidget {
  final SiteSection section;
  final ValueChanged<SiteSection> onSave;

  const _SectionEditSheet({
    required this.section,
    required this.onSave,
  });

  @override
  State<_SectionEditSheet> createState() => _SectionEditSheetState();
}

class _SectionEditSheetState extends State<_SectionEditSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.section.title);
    _contentCtrl = TextEditingController(text: widget.section.content);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifier: ${widget.section.type.label}',
                style: AppTypography.h2),
            const SizedBox(height: AppSpacing.lg),

            Text('Titre', style: AppTypography.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtrl,
              style: AppTypography.body,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                errorText: _titleError,
                hintText: 'Ex : ${widget.section.type.label}',
              ),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Contenu', style: AppTypography.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _contentCtrl,
              maxLines: 4,
              style: AppTypography.body,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Texte de la section...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            NumbiaButton(
              label: 'Sauvegarder',
              onPressed: () {
                final title = _titleCtrl.text.trim();
                if (title.isEmpty) {
                  setState(() =>
                      _titleError = 'Le titre ne peut pas etre vide.');
                  return;
                }
                widget.onSave(widget.section.copyWith(
                  title: title,
                  content: _contentCtrl.text.trim(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

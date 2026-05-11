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
            body: const Center(child: Text('Site introuvable')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Editeur de site'),
            actions: [
              IconButton(
                icon: const Icon(Icons.style_outlined),
                tooltip: 'Changer de template',
                onPressed: () => context.push('/website-type?siteId=$siteId'),
              ),
              IconButton(
                icon: const Icon(Icons.save_outlined),
                onPressed: () {
                  context.read<EditorCubit>().saveSite();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Site sauvegarde'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: site.sections.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
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
                      onDelete: () => context
                          .read<EditorCubit>()
                          .removeSection(section.id),
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
                        onPressed: () => _showAddSectionSheet(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: NumbiaButton(
                        label: 'Apercu',
                        icon: Icons.visibility_outlined,
                        onPressed: () async {
                          await context.read<EditorCubit>().saveSite();
                          if (context.mounted) {
                            context.push('/preview/$siteId');
                          }
                        },
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

  void _showAddSectionSheet(BuildContext context) {
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
                children: SectionType.values
                    .map((type) => ListTile(
                          leading: Icon(_iconForSection(type),
                              color: AppColors.primary),
                          title: Text(type.label, style: AppTypography.body),
                          onTap: () {
                            context.read<EditorCubit>().addSection(type);
                            Navigator.of(context).pop();
                          },
                        ))
                    .toList(),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: NumbiaCard(
        child: Row(
          children: [
            const Icon(Icons.drag_handle, color: AppColors.neutralMid),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: AppTypography.h3),
                  Text(section.type.label, style: AppTypography.caption),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.error),
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
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Contenu', style: AppTypography.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _contentCtrl,
              maxLines: 4,
              style: AppTypography.body,
              decoration: const InputDecoration(
                hintText: 'Texte de la section...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            NumbiaButton(
              label: 'Sauvegarder',
              onPressed: () {
                widget.onSave(widget.section.copyWith(
                  title: _titleCtrl.text,
                  content: _contentCtrl.text,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../../shared/widgets/numbia_card.dart';
import '../../../../shared/widgets/resolved_image.dart';
import '../cubits/editor_cubit.dart';
import '../cubits/editor_state.dart';

/// Product catalog manager for e-commerce sites.
class ProductManagerScreen extends StatelessWidget {
  final String siteId;

  const ProductManagerScreen({super.key, required this.siteId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorCubit, EditorState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Retour',
              onPressed: () => context.pop(),
            ),
            title: const Text('Mes produits'),
          ),
          body: _buildBody(context, state),
          floatingActionButton: state.status == EditorStatus.loaded &&
                  state.products.isNotEmpty
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  tooltip: 'Ajouter un produit',
                  onPressed: () => _showProductForm(context, null),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, EditorState state) {
    if (state.status == EditorStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == EditorStatus.error && state.site == null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Impossible de charger vos produits',
        subtitle: state.error ?? 'Une erreur est survenue.',
        actionLabel: 'Retour au tableau de bord',
        onAction: () => context.go('/dashboard'),
      );
    }

    if (state.products.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Aucun produit',
        subtitle: 'Ajoutez vos produits pour votre catalogue en ligne.',
        actionLabel: 'Ajouter un produit',
        onAction: () => _showProductForm(context, null),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl + AppSpacing.lg, // leave room above the FAB
      ),
      itemCount: state.products.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final product = state.products[index];
        return _ProductTile(
          product: product,
          onEdit: () => _showProductForm(context, product),
          onDelete: () => _confirmDeleteProduct(context, product),
        );
      },
    );
  }

  void _showProductForm(BuildContext context, ProductEntity? product) {
    final cubit = context.read<EditorCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (sheetContext) => _ProductForm(
        product: product,
        siteId: siteId,
        onSave: (p, pickedImagePath) async {
          ProductEntity saved;
          try {
            saved = product == null
                ? await cubit.addProduct(p)
                : await cubit.updateProduct(p);
          } catch (_) {
            if (sheetContext.mounted) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Impossible d\'enregistrer le produit. Verifiez votre connexion et reessayez.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            rethrow;
          }

          // The product itself is saved at this point. A failed photo
          // upload shouldn't undo that or block the merchant — just tell
          // them the photo needs a retry, since the connection may be weak.
          if (pickedImagePath != null) {
            try {
              final url =
                  await cubit.uploadProductImage(saved.id, pickedImagePath);
              cubit.setProductImage(saved.id, url);
            } catch (_) {
              if (sheetContext.mounted) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Produit enregistre, mais la photo n\'a pas pu etre envoyee. Reessayez depuis "Modifier".'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            }
          }

          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  Future<void> _confirmDeleteProduct(
      BuildContext context, ProductEntity product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: Text(
          '"${product.name}" sera retire de votre catalogue. Cette action est irreversible.',
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
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<EditorCubit>().deleteProduct(product.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Impossible de supprimer le produit. Verifiez votre connexion.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _ProductTile extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return NumbiaCard(
      onTap: onEdit,
      child: Row(
        children: [
          // Product photo, or a neutral placeholder when none was added yet.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              width: 56,
              height: 56,
              color: AppColors.neutralLight,
              child: (product.imagePath == null || product.imagePath!.isEmpty)
                  ? const Icon(Icons.image_outlined,
                      color: AppColors.neutralMid)
                  : ResolvedImage(
                      path: product.imagePath!,
                      width: 56,
                      height: 56,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.category.isNotEmpty)
                  Text(
                    product.category.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                Text(
                  product.name,
                  style: AppTypography.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.price.toStringAsFixed(0)} FCFA',
                  style: AppTypography.body.copyWith(
                    color: AppColors.neutralDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppColors.error),
            tooltip: 'Supprimer le produit',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final ProductEntity? product;
  final String siteId;
  final Future<void> Function(ProductEntity, String? pickedImagePath) onSave;

  const _ProductForm({
    this.product,
    required this.siteId,
    required this.onSave,
  });

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _categoryCtrl;
  String? _nameError;
  String? _priceError;
  bool _isSubmitting = false;

  /// Local path of a freshly picked photo, not uploaded yet. Null means
  /// "keep whatever photo the product already has" (or none).
  String? _pickedImagePath;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _descCtrl = TextEditingController(text: widget.product?.description ?? '');
    _priceCtrl = TextEditingController(
        text: widget.product?.price.toStringAsFixed(0) ?? '');
    _categoryCtrl =
        TextEditingController(text: widget.product?.category ?? '');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      // Kept small on purpose: merchants are often on a limited data plan,
      // and this photo will be re-downloaded by every visitor of the site.
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (file != null) setState(() => _pickedImagePath = file.path);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.'));

    setState(() {
      _nameError = name.isEmpty ? 'Le nom du produit est obligatoire.' : null;
      _priceError = (price == null || price <= 0)
          ? 'Entrez un prix valide superieur a 0.'
          : null;
    });
    if (_nameError != null || _priceError != null) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onSave(
        ProductEntity(
          id: widget.product?.id ?? const Uuid().v4(),
          siteId: widget.siteId,
          name: name,
          description: _descCtrl.text.trim(),
          price: price!,
          category: _categoryCtrl.text.trim(),
          imagePath: widget.product?.imagePath,
        ),
        _pickedImagePath,
      );
    } catch (_) {
      // The caller already surfaced a SnackBar; keep the sheet open so the
      // merchant can retry without re-typing everything.
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildPhotoPicker() {
    final existingPath = widget.product?.imagePath;
    final hasPhoto = _pickedImagePath != null ||
        (existingPath != null && existingPath.isNotEmpty);

    return GestureDetector(
      onTap: _pickImage,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color:
                      hasPhoto ? Colors.transparent : AppColors.neutralLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: hasPhoto ? AppColors.primary : AppColors.border,
                    width: hasPhoto ? 2 : 1.5,
                  ),
                  boxShadow: hasPhoto
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: !hasPhoto
                    ? const Icon(Icons.add_a_photo_outlined,
                        size: 30, color: AppColors.neutralMid)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd - 2),
                        child: ResolvedImage(
                          path: _pickedImagePath ?? existingPath!,
                          width: 100,
                          height: 100,
                        ),
                      ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  hasPhoto ? Icons.edit_outlined : Icons.add,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasPhoto ? 'Changer la photo' : 'Ajouter une photo',
            style: AppTypography.label.copyWith(
              color: hasPhoto ? AppColors.primary : AppColors.neutralDark,
            ),
          ),
          if (!hasPhoto) ...[
            const SizedBox(height: 2),
            Text(
              'Une bonne photo aide vos clients a se decider',
              style: AppTypography.caption
                  .copyWith(color: AppColors.neutralMid),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

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
            Text(
              isEditing ? 'Modifier le produit' : 'Nouveau produit',
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.lg),

            Center(child: _buildPhotoPicker()),
            const SizedBox(height: AppSpacing.lg),

            Text('Nom du produit', style: AppTypography.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              style: AppTypography.body,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(errorText: _nameError),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Description', style: AppTypography.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              style: AppTypography.body,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Prix (FCFA)', style: AppTypography.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(),
              style: AppTypography.body,
              decoration: InputDecoration(
                errorText: _priceError,
                hintText: 'Ex : 5000',
              ),
              onChanged: (_) {
                if (_priceError != null) setState(() => _priceError = null);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Categorie', style: AppTypography.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _categoryCtrl,
              style: AppTypography.body,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ex: Patisseries, Accessoires...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            NumbiaButton(
              label: isEditing ? 'Modifier' : 'Ajouter',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

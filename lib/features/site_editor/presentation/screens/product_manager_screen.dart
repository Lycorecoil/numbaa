import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/numbia_button.dart';
import '../../../../shared/widgets/numbia_card.dart';
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
              onPressed: () => context.pop(),
            ),
            title: const Text('Mes produits'),
          ),
          body: state.products.isEmpty
              ? EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucun produit',
                  subtitle: 'Ajoutez vos produits pour votre catalogue en ligne.',
                  actionLabel: 'Ajouter un produit',
                  onAction: () => _showProductForm(context, null),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: state.products.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return _ProductTile(
                      product: product,
                      onEdit: () => _showProductForm(context, product),
                      onDelete: () => context
                          .read<EditorCubit>()
                          .deleteProduct(product.id),
                    );
                  },
                ),
          floatingActionButton: state.products.isNotEmpty
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: () => _showProductForm(context, null),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  void _showProductForm(BuildContext context, ProductEntity? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => _ProductForm(
        product: product,
        siteId: siteId,
        onSave: (p) {
          final cubit = context.read<EditorCubit>();
          if (product == null) {
            cubit.addProduct(p);
          } else {
            cubit.updateProduct(p);
          }
          Navigator.of(context).pop();
        },
      ),
    );
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
          // Product image placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.neutralLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.image_outlined, color: AppColors.neutralMid),
          ),
          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTypography.h3),
                if (product.category.isNotEmpty)
                  Text(product.category, style: AppTypography.caption),
                Text(
                  '${product.price.toStringAsFixed(0)} FCFA',
                  style: AppTypography.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppColors.error),
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
  final ValueChanged<ProductEntity> onSave;

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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
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

            Text('Nom du produit', style: AppTypography.label),
            const SizedBox(height: 6),
            TextFormField(
                controller: _nameCtrl, style: AppTypography.body),
            const SizedBox(height: AppSpacing.md),

            Text('Description', style: AppTypography.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Prix (FCFA)', style: AppTypography.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Categorie', style: AppTypography.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _categoryCtrl,
              style: AppTypography.body,
              decoration: const InputDecoration(
                hintText: 'Ex: Patisseries, Accessoires...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            NumbiaButton(
              label: isEditing ? 'Modifier' : 'Ajouter',
              onPressed: () {
                final name = _nameCtrl.text.trim();
                final price =
                    double.tryParse(_priceCtrl.text.trim()) ?? 0;

                if (name.isEmpty) return;

                widget.onSave(ProductEntity(
                  id: widget.product?.id ?? const Uuid().v4(),
                  siteId: widget.siteId,
                  name: name,
                  description: _descCtrl.text.trim(),
                  price: price,
                  category: _categoryCtrl.text.trim(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

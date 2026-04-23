import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/enums.dart';
import '../../../../domain/entities/site_entity.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../domain/usecases/site/add_product_use_case.dart';
import '../../../../domain/usecases/site/delete_product_use_case.dart';
import '../../../../domain/usecases/site/get_products_use_case.dart';
import '../../../../domain/usecases/site/update_product_use_case.dart';
import '../../../../domain/usecases/site/update_site_use_case.dart';
import 'editor_state.dart';

/// Manages site editing operations.
class EditorCubit extends Cubit<EditorState> {
  final GetProductsUseCase _getProducts;
  final AddProductUseCase _addProduct;
  final UpdateProductUseCase _updateProduct;
  final DeleteProductUseCase _deleteProduct;
  final UpdateSiteUseCase _updateSite;

  EditorCubit({
    required GetProductsUseCase getProducts,
    required AddProductUseCase addProduct,
    required UpdateProductUseCase updateProduct,
    required DeleteProductUseCase deleteProduct,
    required UpdateSiteUseCase updateSite,
  })  : _getProducts = getProducts,
        _addProduct = addProduct,
        _updateProduct = updateProduct,
        _deleteProduct = deleteProduct,
        _updateSite = updateSite,
        super(const EditorState());

  Future<void> loadSite(String siteId) async {
    emit(state.copyWith(status: EditorStatus.loading));
    try {
      // Site entity is provided via loadSiteEntity by the loader widgets.
      emit(state.copyWith(status: EditorStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: EditorStatus.error,
        error: e.toString(),
      ));
    }
  }

  void loadSiteEntity(SiteEntity site) {
    emit(state.copyWith(status: EditorStatus.loaded, site: site));
    if (site.websiteType == WebsiteType.ecommerce) {
      _loadProducts(site.id);
    }
  }

  Future<void> _loadProducts(String siteId) async {
    final products = await _getProducts(siteId);
    emit(state.copyWith(products: products));
  }

  // --- Section operations ---

  void updateSection(SiteSection updated) {
    final site = state.site;
    if (site == null) return;

    final sections = site.sections.map((s) {
      return s.id == updated.id ? updated : s;
    }).toList();

    emit(state.copyWith(site: site.copyWith(sections: sections)));
  }

  void reorderSections(int oldIndex, int newIndex) {
    final site = state.site;
    if (site == null) return;

    final sections = List<SiteSection>.from(site.sections);
    final item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);

    // Recompute order indices
    final reordered = sections.asMap().entries.map((e) {
      return e.value.copyWith(order: e.key);
    }).toList();

    emit(state.copyWith(site: site.copyWith(sections: reordered)));
  }

  void addSection(SectionType type) {
    final site = state.site;
    if (site == null) return;

    final section = SiteSection(
      id: const Uuid().v4(),
      type: type,
      title: type.label,
      order: site.sections.length,
    );

    emit(state.copyWith(
      site: site.copyWith(sections: [...site.sections, section]),
    ));
  }

  void removeSection(String sectionId) {
    final site = state.site;
    if (site == null) return;

    final sections = site.sections.where((s) => s.id != sectionId).toList();
    emit(state.copyWith(site: site.copyWith(sections: sections)));
  }

  // --- Product operations ---

  Future<void> addProduct(ProductEntity product) async {
    final saved = await _addProduct(product);
    emit(state.copyWith(products: [...state.products, saved]));
  }

  Future<void> updateProduct(ProductEntity product) async {
    final updated = await _updateProduct(product);
    final products = state.products.map((p) {
      return p.id == updated.id ? updated : p;
    }).toList();
    emit(state.copyWith(products: products));
  }

  Future<void> deleteProduct(String productId) async {
    final siteId = state.site?.id ?? '';
    await _deleteProduct(siteId, productId);
    final products = state.products.where((p) => p.id != productId).toList();
    emit(state.copyWith(products: products));
  }

  // --- Save ---

  Future<void> saveSite() async {
    final site = state.site;
    if (site == null) return;

    emit(state.copyWith(status: EditorStatus.saving));
    try {
      await _updateSite(site);
      emit(state.copyWith(status: EditorStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: EditorStatus.error,
        error: 'Erreur lors de la sauvegarde',
      ));
    }
  }
}

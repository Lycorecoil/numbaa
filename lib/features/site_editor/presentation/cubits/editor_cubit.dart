import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/enums.dart';
import '../../../../domain/entities/business_entity.dart';
import '../../../../domain/entities/site_entity.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../domain/entities/template_entity.dart';
import '../../../../domain/usecases/site/add_product_use_case.dart';
import '../../../../domain/usecases/site/create_site_use_case.dart';
import '../../../../domain/usecases/site/delete_product_use_case.dart';
import '../../../../domain/usecases/site/get_products_use_case.dart';
import '../../../../domain/usecases/site/update_product_use_case.dart';
import '../../../../domain/usecases/site/update_site_use_case.dart';
import '../../../../domain/usecases/site/upload_product_image_use_case.dart';
import 'editor_state.dart';

/// Manages site editing operations.
class EditorCubit extends Cubit<EditorState> {
  final GetProductsUseCase _getProducts;
  final AddProductUseCase _addProduct;
  final UpdateProductUseCase _updateProduct;
  final DeleteProductUseCase _deleteProduct;
  final UpdateSiteUseCase _updateSite;
  final UploadProductImageUseCase _uploadProductImage;
  final CreateSiteUseCase _createSite;

  EditorCubit({
    required GetProductsUseCase getProducts,
    required AddProductUseCase addProduct,
    required UpdateProductUseCase updateProduct,
    required DeleteProductUseCase deleteProduct,
    required UpdateSiteUseCase updateSite,
    required UploadProductImageUseCase uploadProductImage,
    required CreateSiteUseCase createSite,
  })  : _getProducts = getProducts,
        _addProduct = addProduct,
        _updateProduct = updateProduct,
        _deleteProduct = deleteProduct,
        _updateSite = updateSite,
        _uploadProductImage = uploadProductImage,
        _createSite = createSite,
        super(const EditorState());

  Future<void> loadSite(String siteId) async {
    emit(state.copyWith(status: EditorStatus.loading));
    // Site entity is provided via loadSiteEntity by _EditorLoader.
  }

  void setError(String message) {
    emit(state.copyWith(status: EditorStatus.error, error: message));
  }

  /// Stores the business profile alongside the site so the preview can
  /// render real contact info instead of placeholder data.
  void setBusiness(BusinessEntity business) {
    emit(state.copyWith(business: business));
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

  /// Returns the server-saved product (with its real id) so the caller can
  /// attach an uploaded photo to it right after creation.
  Future<ProductEntity> addProduct(ProductEntity product) async {
    final saved = await _addProduct(product);
    emit(state.copyWith(products: [...state.products, saved]));
    return saved;
  }

  Future<ProductEntity> updateProduct(ProductEntity product) async {
    final updated = await _updateProduct(product);
    final products = state.products.map((p) {
      return p.id == updated.id ? updated : p;
    }).toList();
    emit(state.copyWith(products: products));
    return updated;
  }

  Future<void> deleteProduct(String productId) async {
    final siteId = state.site?.id ?? '';
    await _deleteProduct(siteId, productId);
    final products = state.products.where((p) => p.id != productId).toList();
    emit(state.copyWith(products: products));
  }

  /// Uploads a photo for [productId] (which must already exist server-side)
  /// and returns the resulting image URL/path.
  Future<String> uploadProductImage(String productId, String localFilePath) {
    final siteId = state.site?.id ?? '';
    return _uploadProductImage(siteId, productId, localFilePath);
  }

  /// Applies a newly-uploaded photo to a product already held in state,
  /// without waiting for a full product list refetch.
  void setProductImage(String productId, String imageUrl) {
    final products = state.products.map((p) {
      return p.id == productId ? p.copyWith(imagePath: imageUrl) : p;
    }).toList();
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

  // --- Live editing (fullscreen "tap a template card" editor) ---
  //
  // The classic list editor (editor_screen.dart) always starts from a site
  // that already exists server-side, so updateSection/reorderSections above
  // stay pure in-memory mutations — nothing is persisted until the merchant
  // explicitly saves or leaves the screen. The fullscreen live editor can
  // instead start from a bare template with no site at all, and is meant to
  // save transparently as the merchant edits. To keep that behavior fully
  // separate from the classic editor (so it can never accidentally start
  // autosaving there too), all of it lives in these dedicated methods, which
  // call the plain mutators above and then layer the create/debounce logic
  // on top.

  TemplateEntity? _originTemplate;
  WebsiteType? _originWebsiteType;
  String? _originBusinessId;
  Completer<String>? _originBusinessIdCompleter;
  bool _draftPersisted = true;
  bool _hasLiveEdit = false;
  Timer? _autosaveTimer;

  /// Sentinel id used for the in-memory site built by [beginFromTemplate]
  /// before it has ever been persisted.
  static const unsavedSiteId = '__unsaved_draft__';

  /// True once the current live-editing site has a real, server-assigned
  /// id (either it always had one, or the first edit created it).
  bool get isDraftPersisted => _draftPersisted;

  /// Starts live editing from a template with no site yet — the tap-to-
  /// fullscreen flow from the template catalog, before any site exists.
  /// Builds the in-memory site synchronously (no network call) so the
  /// fullscreen screen has something to show on its very first frame —
  /// this matters because the Hero "expand from card" animation only
  /// plays if the destination's Hero-tagged content already exists in the
  /// tree at push time. The real draft row is only created server-side on
  /// the first actual edit (see [_persistDraftFirstTime]): opening and
  /// closing the fullscreen preview without touching anything never
  /// creates an orphan site.
  ///
  /// [businessId] is resolved separately and lazily via
  /// [setOriginBusinessId] (it normally requires a network call, and must
  /// not block this synchronous first frame); pass it once known.
  void beginFromTemplate({
    required TemplateEntity template,
    required WebsiteType websiteType,
  }) {
    _originTemplate = template;
    _originWebsiteType = websiteType;
    _originBusinessId = null;
    _originBusinessIdCompleter = Completer<String>();
    _draftPersisted = false;
    _hasLiveEdit = false;
    final uuid = const Uuid();
    final sections = template.defaultSections.asMap().entries.map((e) {
      return SiteSection(
        id: uuid.v4(),
        type: e.value,
        title: e.value.label,
        order: e.key,
      );
    }).toList();
    emit(state.copyWith(
      status: EditorStatus.loaded,
      site: SiteEntity(
        id: unsavedSiteId,
        businessId: '',
        templateId: template.id,
        websiteType: websiteType,
        sections: sections,
        primaryColor: template.previewColor,
        createdAt: DateTime.now(),
      ),
    ));
  }

  /// Supplies the business id resolved asynchronously after
  /// [beginFromTemplate] (e.g. once `GetBusinessUseCase` returns) so the
  /// first edit can create the draft without the caller having to block
  /// the fullscreen screen's first frame on that network call.
  void setOriginBusinessId(String businessId) {
    _originBusinessId = businessId;
    if (_originBusinessIdCompleter?.isCompleted == false) {
      _originBusinessIdCompleter!.complete(businessId);
    }
  }

  /// Starts live editing on top of a site that already exists server-side.
  /// When [newTemplate] is given and differs from the site's current
  /// template, the swap is applied and saved immediately — choosing a new
  /// template is a deliberate action, not something to silently discard if
  /// the merchant leaves before making any further edit. Further inline
  /// edits after that autosave with the same debounce as a brand-new draft.
  void beginFromExistingSite(
    SiteEntity site, {
    TemplateEntity? newTemplate,
    WebsiteType? newWebsiteType,
  }) {
    _draftPersisted = true;
    _hasLiveEdit = false;
    final isTemplateSwap =
        newTemplate != null && newTemplate.id != site.templateId;
    if (!isTemplateSwap) {
      loadSiteEntity(site);
      return;
    }
    final uuid = const Uuid();
    final sections = newTemplate.defaultSections.asMap().entries.map((e) {
      return SiteSection(
        id: uuid.v4(),
        type: e.value,
        title: e.value.label,
        order: e.key,
      );
    }).toList();
    final updated = site.copyWith(
      templateId: newTemplate.id,
      websiteType: newWebsiteType ?? site.websiteType,
      sections: sections,
      primaryColor: newTemplate.previewColor,
    );
    emit(state.copyWith(status: EditorStatus.loaded, site: updated));
    if (updated.websiteType == WebsiteType.ecommerce) {
      _loadProducts(updated.id);
    }
    saveSite();
  }

  /// Inline-edits a section's title/content from the fullscreen live
  /// editor, then triggers the create-on-first-edit / debounced-save flow.
  void editSectionInline(SiteSection updated) {
    updateSection(updated);
    _onLiveEditMade();
  }

  /// Drags a section to a new position from the fullscreen live editor,
  /// then triggers the create-on-first-edit / debounced-save flow.
  /// [oldIndex]/[newIndex] follow the same "already adjusted for removal"
  /// contract as [reorderSections] (and `ReorderableListView.onReorderItem`).
  void reorderSectionsInline(int oldIndex, int newIndex) {
    reorderSections(oldIndex, newIndex);
    _onLiveEditMade();
  }

  void _onLiveEditMade() {
    _hasLiveEdit = true;
    _autosaveTimer?.cancel();
    if (!_draftPersisted) {
      _persistDraftFirstTime();
      return;
    }
    // Debounce writes so fast typing doesn't fire an HTTP request per
    // keystroke on what may be a slow, metered connection — the same
    // "save on pause" pattern used elsewhere in the app for search-as-you
    // -type inputs. finishLiveEditing()/commitSelection() flush this
    // immediately when the merchant leaves before the pause elapses.
    _autosaveTimer = Timer(const Duration(milliseconds: 900), saveSite);
  }

  /// Guards against overlapping creations: if a second edit lands while the
  /// first creation request is still in flight (plausible on the slow,
  /// intermittent connections this app targets), this returns the *same*
  /// in-progress future instead of firing a second `_createSite` call that
  /// would otherwise create two draft sites for one template selection.
  Future<void>? _draftCreationInFlight;

  Future<void> _persistDraftFirstTime() {
    return _draftCreationInFlight ??=
        _doPersistDraftFirstTime().whenComplete(() {
      _draftCreationInFlight = null;
    });
  }

  Future<void> _doPersistDraftFirstTime() async {
    final requestSite = state.site;
    final template = _originTemplate;
    final websiteType = _originWebsiteType;
    if (requestSite == null || template == null || websiteType == null) {
      return;
    }
    try {
      final businessId = _originBusinessId ??
          await _originBusinessIdCompleter?.future
              .timeout(const Duration(seconds: 8));
      if (businessId == null) {
        throw Exception('Business introuvable');
      }
      final created = await _createSite(
        businessId: businessId,
        template: template,
        websiteType: websiteType,
        sections: requestSite.sections,
        primaryColor: requestSite.primaryColor,
      );
      _draftPersisted = true;
      // Adopt the server-assigned identity but keep whatever is *currently*
      // in state for the editable fields: another edit may have landed
      // while this request was in flight, and a slow first save must never
      // silently revert it.
      final merged = (state.site ?? requestSite).copyWith(
        id: created.id,
        businessId: created.businessId,
        createdAt: created.createdAt,
      );
      emit(state.copyWith(status: EditorStatus.loaded, site: merged));
      if (merged.websiteType == WebsiteType.ecommerce) {
        _loadProducts(merged.id);
      }
      // The create request above only carried whatever was current *when
      // it was sent*. Push one normal update now so anything that arrived
      // while it was in flight actually reaches the server too.
      saveSite();
    } catch (_) {
      emit(state.copyWith(
        status: EditorStatus.error,
        error:
            'Impossible de creer le brouillon. Verifiez votre connexion et reessayez.',
      ));
    }
  }

  /// Call when leaving the fullscreen live editor without an explicit
  /// "Terminer" — persists a pending edit if there is one, but creates
  /// nothing if the merchant never actually touched anything.
  Future<void> finishLiveEditing() async {
    _autosaveTimer?.cancel();
    if (!_hasLiveEdit) return;
    if (!_draftPersisted) {
      await _persistDraftFirstTime();
    } else {
      await saveSite();
    }
  }

  /// Call for the explicit "Terminer" action — always ensures the site is
  /// persisted (creating the draft even if the merchant made no edit at
  /// all, mirroring the old eager "Choisir ce modele" behavior), and
  /// returns the resulting, always-real, [SiteEntity].
  Future<SiteEntity> commitSelection() async {
    _autosaveTimer?.cancel();
    if (!_draftPersisted) {
      await _persistDraftFirstTime();
    } else {
      await saveSite();
    }
    return state.site!;
  }

  @override
  Future<void> close() {
    _autosaveTimer?.cancel();
    return super.close();
  }
}

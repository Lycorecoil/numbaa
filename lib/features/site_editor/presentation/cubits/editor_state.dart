import 'package:equatable/equatable.dart';
import '../../../../domain/entities/site_entity.dart';
import '../../../../domain/entities/product_entity.dart';

enum EditorStatus { loading, loaded, saving, error }

class EditorState extends Equatable {
  final EditorStatus status;
  final SiteEntity? site;
  final List<ProductEntity> products;
  final String? error;

  const EditorState({
    this.status = EditorStatus.loading,
    this.site,
    this.products = const [],
    this.error,
  });

  EditorState copyWith({
    EditorStatus? status,
    SiteEntity? site,
    List<ProductEntity>? products,
    String? error,
  }) {
    return EditorState(
      status: status ?? this.status,
      site: site ?? this.site,
      products: products ?? this.products,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, site, products, error];
}

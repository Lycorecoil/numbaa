import 'package:equatable/equatable.dart';
import '../../../../domain/entities/business_entity.dart';
import '../../../../domain/entities/site_entity.dart';
import '../../../../domain/entities/product_entity.dart';

enum EditorStatus { loading, loaded, saving, error }

class EditorState extends Equatable {
  final EditorStatus status;
  final SiteEntity? site;
  final BusinessEntity? business;
  final List<ProductEntity> products;
  final String? error;

  const EditorState({
    this.status = EditorStatus.loading,
    this.site,
    this.business,
    this.products = const [],
    this.error,
  });

  EditorState copyWith({
    EditorStatus? status,
    SiteEntity? site,
    BusinessEntity? business,
    List<ProductEntity>? products,
    String? error,
  }) {
    return EditorState(
      status: status ?? this.status,
      site: site ?? this.site,
      business: business ?? this.business,
      products: products ?? this.products,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, site, business, products, error];
}

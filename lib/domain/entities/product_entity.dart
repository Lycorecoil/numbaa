import 'package:equatable/equatable.dart';

/// A product in the e-commerce catalog (simple listing, no cart/checkout).
class ProductEntity extends Equatable {
  final String id;
  final String siteId;
  final String name;
  final String description;
  final double price;
  final String? imagePath;
  final String category;

  const ProductEntity({
    required this.id,
    required this.siteId,
    required this.name,
    this.description = '',
    required this.price,
    this.imagePath,
    this.category = '',
  });

  ProductEntity copyWith({
    String? id,
    String? siteId,
    String? name,
    String? description,
    double? price,
    String? imagePath,
    String? category,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props =>
      [id, siteId, name, description, price, imagePath, category];
}

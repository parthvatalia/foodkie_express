import 'package:equatable/equatable.dart';

class MenuItemModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String categoryId;
  final String? subCategory;
  final String? imageUrl;
  final bool isAvailable;
  final bool isFeatured;
  final Map<String, dynamic>? customizations;

  const MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.categoryId,
    this.subCategory,
    this.imageUrl,
    this.isAvailable = true,
    this.isFeatured = false,
    this.customizations,
  });

  factory MenuItemModel.create({
    required String name,
    String? description,
    required double price,
    required String categoryId,
    String? subCategory,
    String? imageUrl,
    bool isAvailable = true,
    bool isFeatured = false,
    Map<String, dynamic>? customizations,
  }) {
    return MenuItemModel(
      id: '', 
      name: name,
      description: description,
      price: price,
      categoryId: categoryId,
      subCategory: subCategory,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
      isFeatured: isFeatured,
      customizations: customizations,
    );
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String id) {
    return MenuItemModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] ?? 0.0),
      categoryId: map['categoryId'] ?? '',
      subCategory: map['subCategory'],
      imageUrl: map['imageUrl'],
      isAvailable: map['isAvailable'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      customizations: map['customizations'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'subCategory': subCategory,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'customizations': customizations,
    };
  }

  MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? subCategory,
    String? imageUrl,
    bool? isAvailable,
    bool? isFeatured,
    Map<String, dynamic>? customizations,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      subCategory: subCategory ?? this.subCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      customizations: customizations ?? this.customizations,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    categoryId,
    subCategory,
    imageUrl,
    isAvailable,
    isFeatured,
    customizations,
  ];
}
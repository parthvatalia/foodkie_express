import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int order;
  final bool isActive;
  final List<String> subCategories;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.order,
    this.isActive = true,
    this.subCategories = const [],
  });

  factory CategoryModel.create({
    required String name,
    String? description,
    required int order,
    bool isActive = true,
    List<String> subCategories = const [],
  }) {
    return CategoryModel(
      id: '', 
      name: name,
      description: description,
      order: order,
      isActive: isActive,
      subCategories: subCategories,
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
      subCategories: List<String>.from(map['subCategories'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'order': order,
      'isActive': isActive,
      'subCategories': subCategories,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    int? order,
    bool? isActive,
    List<String>? subCategories,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      subCategories: subCategories ?? this.subCategories,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    order,
    isActive,
    subCategories,
  ];
}
import 'package:flutter/material.dart';
import 'package:foodkie_express/api/menu_service.dart';
import 'package:foodkie_express/models/category.dart';
import 'package:foodkie_express/models/item.dart';

class MenuProvider with ChangeNotifier {
  final MenuService _menuService;

  MenuProvider(this._menuService);

  
  Stream<List<CategoryModel>> getCategories() {
    return _menuService.getCategories();
  }

  
  Stream<List<MenuItemModel>> getMenuItems({String? categoryId}) {
    return _menuService.getMenuItems(categoryId: categoryId);
  }

  
  Future<String> addCategory(CategoryModel category) async {
    return await _menuService.addCategory(category);
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _menuService.updateCategory(id, data);
  }

  Future<void> deleteCategory(String id) async {
    await _menuService.deleteCategory(id);
  }

  
  Future<List<MenuItemModel>> searchItems(String query) async {
    return await _menuService.searchItems(query);
  }
}
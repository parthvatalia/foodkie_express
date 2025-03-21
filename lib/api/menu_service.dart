
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/item.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Get categories collection reference
  CollectionReference get _categoriesRef =>
      _firestore.collection('users').doc(_userId).collection('categories');

  // Get items collection reference
  CollectionReference get _itemsRef =>
      _firestore.collection('users').doc(_userId).collection('menuItems');

  // Get all categories
  Stream<List<CategoryModel>> getCategories() {
    return _categoriesRef
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) =>
            CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        ).toList()
    );
  }

  // Add category
  Future<String> addCategory(CategoryModel category) async {
    final docRef = await _categoriesRef.add(category.toMap());
    return docRef.id;
  }

  // Update category
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _categoriesRef.doc(id).update(data);
  }

  // Delete category
  Future<void> deleteCategory(String id) async {
    // Get items in this category
    final items = await _itemsRef.where('categoryId', isEqualTo: id).get();

    // Delete all items in category (batch operation)
    final batch = _firestore.batch();
    for (var doc in items.docs) {
      batch.delete(doc.reference);
    }

    // Delete the category itself
    batch.delete(_categoriesRef.doc(id));

    // Commit batch
    await batch.commit();
  }

  // Get menu items
  Stream<List<MenuItemModel>> getMenuItems({String? categoryId}) {
    var query = _itemsRef.orderBy('name');

    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) =>
            MenuItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        ).toList()
    );
  }

  // Add menu item
  Future<String> addMenuItem(MenuItemModel item, File? imageFile) async {
    // Upload image if provided
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile);
    }

    // Add item with image URL
    final data = item.toMap();
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }

    final docRef = await _itemsRef.add(data);
    return docRef.id;
  }

  // Update menu item
  Future<void> updateMenuItem(
      String id,
      Map<String, dynamic> data,
      File? newImageFile
      ) async {
    // Upload new image if provided
    if (newImageFile != null) {
      final imageUrl = await _uploadImage(newImageFile);
      data['imageUrl'] = imageUrl;
    }

    await _itemsRef.doc(id).update(data);
  }

  // Delete menu item
  Future<void> deleteMenuItem(String id) async {
    // Get the item to check if it has an image
    final doc = await _itemsRef.doc(id).get();
    final data = doc.data() as Map<String, dynamic>?;

    // Delete image if exists
    if (data != null && data.containsKey('imageUrl') ) {
      if(data['imageUrl'] != null){
      final imageUrl = data['imageUrl'];
      if (imageUrl.isNotEmpty) {
        await _deleteImage(imageUrl);
      }
    }
    }

    // Delete the item
    await _itemsRef.doc(id).delete();
  }

  // Helper: Upload image
  Future<String> _uploadImage(File imageFile) async {
    final uuid = Uuid().v4();
    final ref = _storage.ref().child('menuItems/$_userId/$uuid.jpg');

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // Helper: Delete image
  Future<void> _deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Handle or ignore error if image doesn't exist
      print('Error deleting image: $e');
    }
  }

  // Get items by search
  Future<List<MenuItemModel>> searchItems(String query) async {
    query = query.toLowerCase();

    final snapshot = await _itemsRef.get();

    return snapshot.docs
        .map((doc) => MenuItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((item) =>
    item.name.toLowerCase().contains(query) ||
        (item.description?.toLowerCase().contains(query) ?? false)
    )
        .toList();
  }
}
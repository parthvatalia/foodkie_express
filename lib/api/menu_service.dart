
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

  
  CollectionReference get _categoriesRef =>
      _firestore.collection('users').doc(_userId).collection('categories');

  
  CollectionReference get _itemsRef =>
      _firestore.collection('users').doc(_userId).collection('menuItems');

  
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

  
  Future<String> addCategory(CategoryModel category) async {
    final docRef = await _categoriesRef.add(category.toMap());
    return docRef.id;
  }

  
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _categoriesRef.doc(id).update(data);
  }

  
  Future<void> deleteCategory(String id) async {
    
    final items = await _itemsRef.where('categoryId', isEqualTo: id).get();

    
    final batch = _firestore.batch();
    for (var doc in items.docs) {
      batch.delete(doc.reference);
    }

    
    batch.delete(_categoriesRef.doc(id));

    
    await batch.commit();
  }

  
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

  
  Future<String> addMenuItem(MenuItemModel item, File? imageFile) async {
    
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile);
    }

    
    final data = item.toMap();
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }

    final docRef = await _itemsRef.add(data);
    return docRef.id;
  }

  
  Future<void> updateMenuItem(
      String id,
      Map<String, dynamic> data,
      File? newImageFile
      ) async {
    
    if (newImageFile != null) {
      final imageUrl = await _uploadImage(newImageFile);
      data['imageUrl'] = imageUrl;
    }

    await _itemsRef.doc(id).update(data);
  }

  
  Future<void> deleteMenuItem(String id) async {
    
    final doc = await _itemsRef.doc(id).get();
    final data = doc.data() as Map<String, dynamic>?;

    
    if (data != null && data.containsKey('imageUrl') ) {
      if(data['imageUrl'] != null){
      final imageUrl = data['imageUrl'];
      if (imageUrl.isNotEmpty) {
        await _deleteImage(imageUrl);
      }
    }
    }

    
    await _itemsRef.doc(id).delete();
  }

  
  Future<String> _uploadImage(File imageFile) async {
    final uuid = const Uuid().v4();
    final ref = _storage.ref().child('menuItems/$_userId/$uuid.jpg');

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  
  Future<void> _deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      
      print('Error deleting image: $e');
    }
  }

  
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
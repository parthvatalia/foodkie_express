import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  
  Future<RestaurantProfile?> getRestaurantProfile() async {
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || !data.containsKey('restaurantProfile')) {
      return null;
    }

    return RestaurantProfile.fromMap(data['restaurantProfile']);
  }

  
  Future<void> saveRestaurantProfile(
      RestaurantProfile profile,
      {File? logoFile}
      ) async {
    Map<String, dynamic> profileData = profile.toMap();

    
    if (logoFile != null) {
      final logoUrl = await _uploadLogo(logoFile);
      profileData['logoUrl'] = logoUrl;
    }

    await _firestore
        .collection('users')
        .doc(_userId)
        .set({
      'restaurantProfile': profileData
    }, SetOptions(merge: true));
  }

  
  Future<String> _uploadLogo(File logoFile) async {
    final ref = _storage.ref().child('restaurantLogos/$_userId/logo.jpg');

    await ref.putFile(logoFile);
    return await ref.getDownloadURL();
  }

  
  Future<Map<String, dynamic>?> getBusinessHours() async {
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || !data.containsKey('businessHours')) {
      return null;
    }

    return data['businessHours'] as Map<String, dynamic>;
  }

  
  Future<void> saveBusinessHours(Map<String, dynamic> hours) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .set({
      'businessHours': hours
    }, SetOptions(merge: true));
  }

  
  Future<Map<String, dynamic>?> getPrintSettings() async {
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || !data.containsKey('printSettings')) {
      return null;
    }

    return data['printSettings'] as Map<String, dynamic>;
  }

  
  Future<void> savePrintSettings(Map<String, dynamic> settings) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .set({
      'printSettings': settings
    }, SetOptions(merge: true));
  }

  
  Future<void> saveDeviceToken(String token) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .set({
      'deviceTokens': FieldValue.arrayUnion([token])
    }, SetOptions(merge: true));
  }

  
  Future<void> removeDeviceToken(String token) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .update({
      'deviceTokens': FieldValue.arrayRemove([token])
    });
  }
}
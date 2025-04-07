import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  User? get currentUser => _auth.currentUser;

  
  Stream<User?> get userStream => _auth.authStateChanges();


  Future<void> sendOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) async {
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('verificationId', verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          
          debugPrint('OTP auto-retrieval timeout');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      
      rethrow;
    }
  }

  Future<UserCredential> verifyOTP(String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final verificationId = prefs.getString('verificationId');

      if (verificationId == null || verificationId.isEmpty) {
        throw FirebaseAuthException(
            code: 'invalid-verification-id',
            message: 'Verification ID is missing. Please request OTP again.'
        );
      }

      
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      
      if (e is FirebaseAuthException) {
        rethrow;
      }
      throw FirebaseAuthException(
          code: 'verification-failed',
          message: 'Failed to verify OTP: ${e.toString()}'
      );
    }
  }

  
  Future<bool> checkUserProfileExists() async {
    if (currentUser == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    return doc.exists;
  }

  
  Future<void> createUserProfile(UserModel user) async {
    if (currentUser == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .set(user.toMap());
  }

  
  Future<UserModel?> getUserProfile() async {
    if (currentUser == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!, doc.id);
  }

  
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUser == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .update(data);
  }

  
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
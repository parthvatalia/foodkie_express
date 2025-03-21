import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user stream
  Stream<User?> get userStream => _auth.authStateChanges();

// In auth_service.dart
  Future<void> sendOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          // Forward the error to be handled by the calling code
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) async {
          // Save verification ID to be used when verifying the code
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('verificationId', verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout for auto-retrieval, usually just logs
          debugPrint('OTP auto-retrieval timeout');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      // Rethrow to let the UI handle the error appropriately
      throw e;
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

      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Sign in and return UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // Rethrow with more context if needed
      if (e is FirebaseAuthException) {
        throw e;
      }
      throw FirebaseAuthException(
          code: 'verification-failed',
          message: 'Failed to verify OTP: ${e.toString()}'
      );
    }
  }

  // Check if user profile exists
  Future<bool> checkUserProfileExists() async {
    if (currentUser == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    return doc.exists;
  }

  // Create user profile
  Future<void> createUserProfile(UserModel user) async {
    if (currentUser == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .set(user.toMap());
  }

  // Get user profile
  Future<UserModel?> getUserProfile() async {
    if (currentUser == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUser == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .update(data);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
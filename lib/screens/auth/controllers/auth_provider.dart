import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodkie_express/api/auth_service.dart';
import 'package:foodkie_express/models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  bool _isLoading = false;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthProvider(this._authService);

  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _authService.currentUser != null;

  // Check if user is logged in and fetch profile
  Future<bool> checkIfLoggedIn() async {
    if (_authService.currentUser == null) return false;

    try {
      _setLoading(true);
      _errorMessage = null;

      // Get user profile from Firestore
      final userProfile = await _authService.getUserProfile();

      if (userProfile != null) {
        _currentUser = userProfile;
        _setLoading(false);
        return true;
      } else {
        // User is authenticated but no profile exists
        _setLoading(false);
        return true; // Still return true, the app will need to create profile
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.sendOTP(phoneNumber);

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      throw e;
    }
  }

  Future<bool> verifyOTP(String otp) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      try {
        final credential = await _authService.verifyOTP(otp);

        // Normal auth flow successful
        // Check if user profile exists
        final profileExists = await _authService.checkUserProfileExists();

        if (profileExists) {
          // Fetch user profile
          final userProfile = await _authService.getUserProfile();
          _currentUser = userProfile;
        } else {
          // Create basic user profile if it doesn't exist
          final user = credential.user;
          if (user != null) {
            final newUser = UserModel(
              id: user.uid,
              phoneNumber: user.phoneNumber ?? '',
              createdAt: Timestamp.now(),
            );

            await _authService.createUserProfile(newUser);
            _currentUser = newUser;
          }
        }

        _setLoading(false);
        return true;
      } catch (e) {
        // Check if this is our development mode signal
        if (e.toString().contains('dev_mode_auth_success')) {
          // Development mode authentication
          // Create a test user profile
          final testUser = UserModel(
            id: 'dev_user_id',
            phoneNumber: '+1234567890',
            createdAt: Timestamp.now(),
          );

          _currentUser = testUser;
          _setLoading(false);
          return true;
        }

        // Handle other errors normally
        throw e;
      }
    } catch (e) {
      _setError(e.toString());
      throw e;
    }
  }

  // Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.updateUserProfile(data);

      // Refresh user data
      final updatedUser = await _authService.getUserProfile();
      _currentUser = updatedUser;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.signOut();
      _currentUser = null;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      throw e;
    }
  }

  // Helper for setting loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Helper for setting error
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }
}
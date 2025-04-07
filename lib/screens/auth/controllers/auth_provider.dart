import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  
  Future<bool> checkIfLoggedIn() async {
    if (_authService.currentUser == null) return false;

    try {
      _setLoading(true);
      _errorMessage = null;

      
      final userProfile = await _authService.getUserProfile();

      if (userProfile != null) {
        _currentUser = userProfile;
        _setLoading(false);
        return true;
      } else {
        
        _setLoading(false);
        return true; 
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  
  Future<void> sendOTP(String phoneNumber) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.sendOTP(phoneNumber);

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<bool> verifyOTP(String otp) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      try {
        final credential = await _authService.verifyOTP(otp);

        
        
        final profileExists = await _authService.checkUserProfileExists();

        if (profileExists) {
          
          final userProfile = await _authService.getUserProfile();
          _currentUser = userProfile;
        } else {
          
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
        
        if (e.toString().contains('dev_mode_auth_success')) {
          
          
          final testUser = UserModel(
            id: 'dev_user_id',
            phoneNumber: '+1234567890',
            createdAt: Timestamp.now(),
          );

          _currentUser = testUser;
          _setLoading(false);
          return true;
        }

        
        rethrow;
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.updateUserProfile(data);

      
      final updatedUser = await _authService.getUserProfile();
      _currentUser = updatedUser;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.signOut();
      _currentUser = null;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }
}
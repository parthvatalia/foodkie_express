import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String phoneNumber;
  final String? displayName;
  final String? email;
  final String? profileImageUrl;
  final Timestamp createdAt;
  final Timestamp? lastLoginAt;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    this.displayName,
    this.email,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'],
      email: map['email'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      lastLoginAt: map['lastLoginAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? displayName,
    String? email,
    String? profileImageUrl,
    Timestamp? createdAt,
    Timestamp? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    phoneNumber,
    displayName,
    email,
    profileImageUrl,
    createdAt,
    lastLoginAt,
  ];
}
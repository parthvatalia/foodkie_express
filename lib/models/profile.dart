import 'package:equatable/equatable.dart';

class RestaurantProfile extends Equatable {
  final String name;
  final String? logoUrl;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? phoneNumber;
  final String? email;
  final String? description;
  final String? taxId;
  final double taxPercentage;
  final bool applyTaxToAll;
  final bool isActive;

  const RestaurantProfile({
    required this.name,
    this.logoUrl,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.phoneNumber,
    this.email,
    this.description,
    this.taxId,
    this.taxPercentage = 0.0,
    this.applyTaxToAll = false,
    this.isActive = true,
  });

  factory RestaurantProfile.fromMap(Map<String, dynamic> map) {
    return RestaurantProfile(
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      zipCode: map['zipCode'],
      country: map['country'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      description: map['description'],
      taxId: map['taxId'],
      taxPercentage: (map['taxPercentage'] is int)
          ? (map['taxPercentage'] as int).toDouble()
          : (map['taxPercentage'] ?? 0.0),
      applyTaxToAll: map['applyTaxToAll'] ?? false,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'phoneNumber': phoneNumber,
      'email': email,
      'description': description,
      'taxId': taxId,
      'taxPercentage': taxPercentage,
      'applyTaxToAll': applyTaxToAll,
      'isActive': isActive,
    };
  }

  RestaurantProfile copyWith({
    String? name,
    String? logoUrl,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? phoneNumber,
    String? email,
    String? description,
    String? taxId,
    double? taxPercentage,
    bool? applyTaxToAll,
    bool? isActive,
  }) {
    return RestaurantProfile(
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      description: description ?? this.description,
      taxId: taxId ?? this.taxId,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      applyTaxToAll: applyTaxToAll ?? this.applyTaxToAll,
      isActive: isActive ?? this.isActive,
    );
  }

  String get formattedAddress {
    List<String> parts = [];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    if (country != null && country!.isNotEmpty) parts.add(country!);

    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
    name,
    logoUrl,
    address,
    city,
    state,
    zipCode,
    country,
    phoneNumber,
    email,
    description,
    taxId,
    taxPercentage,
    applyTaxToAll,
    isActive,
  ];
}
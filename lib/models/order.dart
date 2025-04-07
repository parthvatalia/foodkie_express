import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class OrderModel extends Equatable {
  final String id;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? notes;
  final String? orderNumber;
  final String? customerName;
  final String? customerPhone;
  final String paymentMethod;

  const OrderModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.orderNumber,
    this.customerName,
    this.customerPhone,
    this.paymentMethod = 'Cash', 
  });

  factory OrderModel.create({
    required List<OrderItem> items,
    required double totalAmount,
    String status = 'pending',
    String? notes,
    String? customerName,
    String? customerPhone,
    String paymentMethod = 'Cash',
  }) {
    
    final now = DateTime.now();
    final datePart = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomPart = (1000 + now.millisecondsSinceEpoch % 9000).toString();
    final orderNumber = '$datePart-$randomPart';

    return OrderModel(
      id: '',
      items: items,
      totalAmount: totalAmount,
      status: status,
      notes: notes,
      orderNumber: orderNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      paymentMethod: paymentMethod,
    );
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      totalAmount: (map['totalAmount'] is int)
          ? (map['totalAmount'] as int).toDouble()
          : (map['totalAmount'] ?? 0.0),
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
      notes: map['notes'],
      orderNumber: map['orderNumber'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      paymentMethod: map['paymentMethod'] ?? 'Cash',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'notes': notes,
      'orderNumber': orderNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'paymentMethod': paymentMethod,
    };
  }

  OrderModel copyWith({
    String? id,
    List<OrderItem>? items,
    double? totalAmount,
    String? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? notes,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    String? paymentMethod,
  }) {
    return OrderModel(
      id: id ?? this.id,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  List<Object?> get props => [
    id,
    items,
    totalAmount,
    status,
    createdAt,
    updatedAt,
    notes,
    orderNumber,
    customerName,
    customerPhone,
    paymentMethod,
  ];
}

class OrderItem extends Equatable {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final Map<String, dynamic>? customizations;
  final String? notes;

  const OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.customizations,
    this.notes,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] ?? 0.0),
      quantity: map['quantity'] ?? 1,
      customizations: map['customizations'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'customizations': customizations,
      'notes': notes,
    };
  }

  double get totalPrice => price * quantity;

  OrderItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    Map<String, dynamic>? customizations,
    String? notes,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      customizations: customizations ?? this.customizations,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    quantity,
    customizations,
    notes,
  ];
}
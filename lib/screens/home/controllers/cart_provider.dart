import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  String? notes;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.notes,
  });

  double get totalPrice => price * quantity;

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? notes,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final _uuid = Uuid();

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(
      0, (sum, item) => sum + (item.price * item.quantity)
  );

  bool get isEmpty => _items.isEmpty;

  void addItem({
    required String id,
    required String name,
    required double price,
    int quantity = 1,
    String? notes,
  }) {
    // Check if item already exists in cart
    final existingIndex = _items.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      // Increment quantity if item exists
      _items[existingIndex].quantity += quantity;
    } else {
      // Add new item if it doesn't exist
      _items.add(CartItem(
        id: id,
        name: name,
        price: price,
        quantity: quantity,
        notes: notes,
      ));
    }

    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void incrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void updateItemNotes(String id, String? notes) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].notes = notes;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Get item by ID
  CartItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if item exists in cart
  bool containsItem(String id) {
    return _items.any((item) => item.id == id);
  }

  // Add a temporary item (not in menu)
  void addCustomItem({
    required String name,
    required double price,
    int quantity = 1,
    String? notes,
  }) {
    final customId = _uuid.v4();

    _items.add(CartItem(
      id: customId,
      name: name,
      price: price,
      quantity: quantity,
      notes: notes,
    ));

    notifyListeners();
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MenuDataLoader {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  static Future<void> loadInitialMenuData(String userId) async {
    try {
      
      final categoriesSnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('categories')
              .limit(1)
              .get();

      if (categoriesSnapshot.docs.isEmpty) {
        debugPrint('Loading initial menu data for user $userId...');
        await _loadCategories(userId);
        await _loadMenuItems(userId);
        debugPrint('Initial menu data loaded successfully!');
      } else {
        debugPrint(
          'Menu data already exists for user $userId, skipping initial load',
        );
      }
    } catch (e) {
      debugPrint('Error loading initial menu data: $e');
    }
  }

  static Future<void> _loadCategories(String userId) async {
    
    final categoriesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('categories');

    
    final pizzaCategoryRef = await categoriesRef.add({
      'name': 'Pizza',
      'description': 'Delicious pizzas with variety of toppings',
      'order': 1,
      'isActive': true,
      'subCategories': ['Live Dough Pizza', 'Chef\'s Special Pizza'],
    });

    
    await categoriesRef.add({
      'name': 'Sandwich',
      'description': 'Variety of sandwiches',
      'order': 2,
      'isActive': true,
      'subCategories': [],
    });

    
    await categoriesRef.add({
      'name': 'Garlic Bread',
      'description': 'Freshly baked garlic bread',
      'order': 3,
      'isActive': true,
      'subCategories': [],
    });

    
    await categoriesRef.add({
      'name': 'Waffle',
      'description': 'Sweet and savory waffles',
      'order': 4,
      'isActive': true,
      'subCategories': [],
    });

    
    await categoriesRef.add({
      'name': 'McCain French Fries',
      'description': 'Crispy french fries',
      'order': 5,
      'isActive': true,
      'subCategories': [],
    });

    
    await categoriesRef.add({
      'name': 'Extra Dips',
      'description': 'Additional dips for your food',
      'order': 6,
      'isActive': true,
      'subCategories': [],
    });
  }

  static Future<void> _loadMenuItems(String userId) async {
    
    final QuerySnapshot categories =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .get();

    Map<String, String> categoryMap = {};
    for (var doc in categories.docs) {
      categoryMap[doc.get('name')] = doc.id;
    }

    
    final menuItemsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('menuItems');

    
    
    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'MARGHERITA',
      price: 154.0,
      description:
          'In-House Pomodoro Sauce, 100% Mozzarella Cheese, Basil Leaves',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Live Dough Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CORN & CHEESE PIZZA',
      price: 235.0,
      description:
          'Sweet Giant Corn, 100% Mozzarella Cheese With Flavour Full Signature Spices In Italian Sauce',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Live Dough Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CLASSIC CORN CAPSICUM PIZZA',
      price: 252.0,
      description:
          'In-House Marinara Sauce, Crunchy Onion, Capsicum, Flavourful Dressing',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Live Dough Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'SPICY SWEET CORN, ONION & CHILLI PIZZA',
      price: 262.0,
      description:
          'In-House Spicy Marinara Sauce, Juicy Sweet Corn, Crunchy Onion, Spicy Green Chilli, Flavour Full Dressing',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Live Dough Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'PANEER MAKHANI PIZZA',
      price: 358.0,
      description:
          'A Burst Of Indian Flavour With Spicy Tangy Layer Of Makhni Sauce Topped With Onion, Capsicum, Green Chilli And Paneer',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Live Dough Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'TANDOORI PANEER PIZZA',
      price: 365.0,
      description:
          'Diced Paneer, Crunchy Onion, Green Capsicum Juicy Red Paprika With Tandoori Sauce 100% Mozzarella',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Live Dough Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'BOLD BBQ VEGGIES PIZZA',
      price: 362.0,
      description:
          'BBQ Sauce, With BBQ Sauce Drizzle, Topped With Mushroom, Onion, Green Capsicum (Writer Prepare)',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Live Dough Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'MAXICAN FIESTA PIZZA',
      price: 372.0,
      description:
          'Red Bell Pepper, Green Capsicum, Jalapeno, Onion, Black Olives, Sweet Corn, and 100% Mozzarella Cheese With A Signature Spice Sprinkle Of Tomatillo Sauce',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Live Dough Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'INDIANA PIZZA',
      price: 327.0,
      description:
          'Loaded With Halved Onion & Green Capsicum, Sweet Corn, Tomato With Signature Pan Marinara Sauce And 100% Mozzarella Cheese',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Live Dough Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'ULTIMATE TANDOORI VEGGIE PIZZA',
      price: 378.0,
      description:
          'Combination Of Your Favourite Veggies Onion, Green Capsicum, Mushroom, Paneer, Spicy Jalapeno, In Tandoori Sauce Topped With 100% Mozzarella Cheese & Mint Sauce',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Live Dough Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'ITALIAN VEGGIE SUPREME PIZZA',
      price: 362.0,
      description:
          'Black Olives, Jalapeno, Green Capsicum, Broccoli, Onion, Red And Yellow Bell Pepper And A Blend Of Corn With Mushroom Sauce And 100% Mozzarella Cheese',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Live Dough Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    
    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'BESIL PESTO PIZZA',
      price: 319.0,
      description:
          'In-House Pesto Sauce, Cherry Tomato, 100% Mozzarella Cheese, Fresh Basil',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Chef\'s Special Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'PESTO ROASTED VEGE PIZZA',
      price: 352.0,
      description:
          '100% Mozzarella, Red & Yellow Bell Pepper, Broccoli, Pesto Sauce, Button Mushroom, Onion',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Chef\'s Special Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'SUN DRIED TOMATO PIZZA',
      price: 234.0,
      description:
          'Sun Dried Tomato Sauce, Onion, Capsicum, Sun-dried Tomato, Jalapeno, Mozzarella & Oregano',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Chef\'s Special Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'SPICY JALEPENO PIZZA',
      price: 234.0,
      description: 'Jalapeno, Marinara Sauce, Onion, 100% Mozzarella Cheese',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Chef\'s Special Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'SRIRACHA',
      price: 320.0,
      description: 'This Is A Spicy & Try You Will Love It',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Chef\'s Special Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'STAR PIZZA',
      price: 289.0,
      description:
          'Tomato Sauce, Capsicum Onion, Corn, Panir, 100% Mozzarella Cheese',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Chef\'s Special Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'FOUR IN ONE PIZZA',
      price: 262.0,
      description: '100% Mozzarella, Capsicum, Corn, Paprika, Black Olives',
      categoryId: categoryMap['Pizza'] ?? '',
      subCategory: 'Chef\'s Special Pizza',
      isAvailable: true,
      isFeatured: false,
    );

    
    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'BREAD BUTTER SANDWICH',
      price: 79.0,
      description: 'Classic bread with butter',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'BREAD BUTTER JAM SANDWICH',
      price: 123.0,
      description: 'Bread with butter and jam',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'VEGETABLE SANDWICH',
      price: 113.0,
      description: 'Fresh vegetables in sandwich',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CHEESE VEGETABLE SANDWICH',
      price: 125.0,
      description: 'Vegetables with cheese',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'VEGETABLE TOAST SANDWICH',
      price: 135.0,
      description: 'Toasted vegetable sandwich',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'VEGETABLE GRILLED SANDWICH',
      price: 154.0,
      description: 'Grilled sandwich with vegetables',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CHEESE VEG. GRILLED SANDWICH',
      price: 187.0,
      description: 'Grilled sandwich with cheese and vegetables',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CHEESE GARLIC SANDWICH',
      price: 156.0,
      description: 'Cheese and garlic sandwich',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'PANEER TANDOORI SANDWICH',
      price: 262.0,
      description: 'Tandoori paneer sandwich',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CHEESE PANNI SANDWICH',
      price: 287.0,
      description: 'Cheese panini sandwich',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'RIMJIM SANDWICH',
      price: 293.0,
      description: 'Specialty rimjim sandwich',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CHEESE BLAST SANDWICH',
      price: 278.0,
      description: 'Extra cheese sandwich',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CHEESE VEGETABLE TOAST SANDWICH',
      price: 157.0,
      description: 'Toasted sandwich with cheese and vegetables',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'ITALIAN SANDWICH',
      price: 254.0,
      description: 'Italian style sandwich',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'TANDURI PANNI SANDWICH',
      price: 289.0,
      description: 'Tandoori panini sandwich',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CHEESE CHILLY SANDWICH',
      price: 167.0,
      description: 'Cheese and chili sandwich',
      categoryId: categoryMap['Sandwich'] ?? '',
      isAvailable: true,
    );

    
    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CLASSIC GARLIC BREAD',
      price: 198.0,
      description: 'Classic garlic bread',
      categoryId: categoryMap['Garlic Bread'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CHEESE GARLIC BREAD',
      price: 223.0,
      description: 'Garlic bread with cheese',
      categoryId: categoryMap['Garlic Bread'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'ITALIAAN GARLIC BREAD',
      price: 234.0,
      description: 'Olives, Capsicum, Bell Pepper, Corn, Green Olives, Cheese',
      categoryId: categoryMap['Garlic Bread'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'GREEN CHILLI GARLIC BREAD',
      price: 223.0,
      description: 'Chilli, Cheese, Garlic',
      categoryId: categoryMap['Garlic Bread'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'TANDOORI GARLIC BREAD',
      price: 237.0,
      description: 'Paneer, Tandoori Sauce',
      categoryId: categoryMap['Garlic Bread'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'PESTO BASIL GARLIC BREAD',
      price: 371.0,
      description: 'Pesto Sauce, Basil, Olives, Cheese',
      categoryId: categoryMap['Garlic Bread'] ?? '',
      isAvailable: true,
    );

    
    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'NAKED NUTELLA WAFFLE',
      price: 195.0,
      description: 'Waffle with Nutella',
      categoryId: categoryMap['Waffle'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'KITKAT WAFFLE',
      price: 185.0,
      description: 'Waffle with KitKat',
      categoryId: categoryMap['Waffle'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CHOCOBITE OVERLOAD DARK WAFFLE',
      price: 175.0,
      description: 'Chocolate waffle',
      categoryId: categoryMap['Waffle'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'ALMOND CRUNCH WAFFLE',
      price: 195.0,
      description: 'Waffle with almonds',
      categoryId: categoryMap['Waffle'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'DARK & WHITE FANTASTY WAFFLE',
      price: 175.0,
      description: 'Dark and white chocolate waffle',
      categoryId: categoryMap['Waffle'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'BISCOFF WAFFLE',
      price: 195.0,
      description: 'Waffle with Biscoff',
      categoryId: categoryMap['Waffle'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'COFFEE MOCHA WAFFLE',
      price: 155.0,
      description: 'Coffee mocha flavored waffle',
      categoryId: categoryMap['Waffle'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'RED VELEVET WAFFLE',
      price: 175.0,
      description: 'Red velvet waffle',
      categoryId: categoryMap['Waffle'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'KUNAFFA WAFFLE',
      price: 220.0,
      description: 'Kunaffa waffle',
      categoryId: categoryMap['Waffle'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'STRAWBERRY WAFFLE',
      price: 145.0,
      description: 'Strawberry waffle',
      categoryId: categoryMap['Waffle'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'BELGIAN CHOCOMELT WAFFLE',
      price: 165.0,
      description: 'Belgian chocolate waffle',
      categoryId: categoryMap['Waffle'] ?? '',
      isAvailable: true,
    );

    
    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'SALTED FRIES',
      price: 120.0,
      description: 'Classic salted fries',
      categoryId: categoryMap['McCain French Fries'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'PERIPERI FRIES',
      price: 135.0,
      description: 'Fries with peri peri seasoning',
      categoryId: categoryMap['McCain French Fries'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CHEESY PERIPERI FRIES',
      price: 154.0,
      description: 'Fries with cheese and peri peri',
      categoryId: categoryMap['McCain French Fries'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'FRIES WITH CHIPOTTLE DIP',
      price: 157.0,
      description: 'Fries with chipotle dip',
      categoryId: categoryMap['McCain French Fries'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'FRIES WITH CHILLI GARLIC DIP',
      price: 157.0,
      description: 'Fries with chili garlic dip',
      categoryId: categoryMap['McCain French Fries'] ?? '',
      isAvailable: true,
    );

    
    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CHEESE DIP',
      price: 48.0,
      description: 'Cheese dip',
      categoryId: categoryMap['Extra Dips'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'CHIPOTTLE DIP',
      price: 48.0,
      description: 'Chipotle dip',
      categoryId: categoryMap['Extra Dips'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'PERI PERI DIP',
      price: 54.0,
      description: 'Peri peri dip',
      categoryId: categoryMap['Extra Dips'] ?? '',
      isAvailable: true,
    );

    await _addMenuItem(
      menuItemsRef: menuItemsRef,
      name: 'SRIRACHA DIP',
      price: 67.0,
      description: 'Sriracha dip',
      categoryId: categoryMap['Extra Dips'] ?? '',
      isAvailable: true,
    );
  }

  static Future<void> _addMenuItem({
    required CollectionReference menuItemsRef,
    required String name,
    required double price,
    required String description,
    required String categoryId,
    String? subCategory,
    bool isAvailable = true,
    bool isFeatured = false,
  }) async {
    await menuItemsRef.add({
      'name': name,
      'price': price,
      'description': description,
      'categoryId': categoryId,
      'subCategory': subCategory,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

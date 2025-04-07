
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  
  CollectionReference get _ordersRef =>
      _firestore.collection('users').doc(_userId).collection('orders');

  
  Future<String> createOrder(OrderModel order) async {
    try {
      
      int orderNumber = await getNextOrderNumber();

      
      final data = order.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['orderNumber'] = orderNumber.toString();

      final docRef = await _ordersRef.add(data);
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }
  Future<String> updateOrder(OrderModel order) async {
    try {



      final data = order.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['orderNumber'] = order.orderNumber.toString();

      final docRef = await _ordersRef.add(data);
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }
  
  Future<int> getNextOrderNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    int orderNumber = 1; 

    
    await _firestore.runTransaction((transaction) async {
      
      final counterRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('counters')
          .doc('orders');

      
      final snapshot = await transaction.get(counterRef);

      if (snapshot.exists) {
        
        orderNumber = (snapshot.data()?['currentCount'] ?? 0) + 1;
        transaction.update(counterRef, {
          'currentCount': orderNumber,
          'updatedAt': FieldValue.serverTimestamp()
        });
      } else {
        
        orderNumber = 1;
        transaction.set(counterRef, {
          'currentCount': orderNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp()
        });
      }
    });

    return orderNumber;
  }

  
  Stream<List<OrderModel>> getOrders() {
    return _ordersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return OrderModel.fromMap(data, doc.id);
        }).toList()
    );
  }

  
  Future<OrderModel?> getOrderById(String id) async {
    final doc = await _ordersRef.doc(id).get();

    if (!doc.exists) return null;

    return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  
  Future<void> updateOrderStatus(String id, String status) async {
    await _ordersRef.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  
  Future<List<OrderModel>> getOrdersByDateRange(
      DateTime startDate,
      DateTime endDate
      ) async {
    
    final start = Timestamp.fromDate(startDate);
    final end = Timestamp.fromDate(endDate.add(const Duration(days: 1)));

    final snapshot = await _ordersRef
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThan: end)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return OrderModel.fromMap(data, doc.id);
    }).toList();
  }

  
  Future<Map<String, dynamic>> getOrderStatistics() async {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfWeek = startOfToday.subtract(
        Duration(days: today.weekday - 1)
    );
    final startOfMonth = DateTime(today.year, today.month, 1);

    
    final todayOrders = await getOrdersByDateRange(
        startOfToday, today
    );

    
    final weekOrders = await getOrdersByDateRange(
        startOfWeek, today
    );

    
    final monthOrders = await getOrdersByDateRange(
        startOfMonth, today
    );

    
    final todayTotal = _calculateTotal(todayOrders);
    final weekTotal = _calculateTotal(weekOrders);
    final monthTotal = _calculateTotal(monthOrders);

    return {
      'todayOrders': todayOrders.length,
      'todayTotal': todayTotal,
      'weekOrders': weekOrders.length,
      'weekTotal': weekTotal,
      'monthOrders': monthOrders.length,
      'monthTotal': monthTotal
    };
  }

  
  double _calculateTotal(List<OrderModel> orders) {
    return orders.fold(0, (sum, order) => sum + order.totalAmount);
  }

  
  Future<void> deleteOrder(String id) async {
    await _ordersRef.doc(id).delete();
  }
}
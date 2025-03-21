
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Get orders collection reference
  CollectionReference get _ordersRef =>
      _firestore.collection('users').doc(_userId).collection('orders');

  // Create new order
  Future<String> createOrder(OrderModel order) async {
    try {
      // Get next sequential order number
      int orderNumber = await getNextOrderNumber();

      // Add timestamp and order number
      final data = order.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['orderNumber'] = orderNumber.toString();

      final docRef = await _ordersRef.add(data);
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      throw e;
    }
  }
  Future<int> getNextOrderNumber() async {
    try {
      // Use Firestore transaction to safely increment the counter
      int orderNumber = 1; // Default starting number

      await _firestore.runTransaction((transaction) async {
        // Get reference to the counter document
        final counterRef = _firestore.collection('counters').doc('orders');
        final snapshot = await transaction.get(counterRef);

        if (snapshot.exists) {
          // Increment existing counter
          orderNumber = (snapshot.data()?['currentNumber'] ?? 0) + 1;
          transaction.update(counterRef, {'currentNumber': orderNumber});
        } else {
          // Create counter document if it doesn't exist
          orderNumber = 1;
          transaction.set(counterRef, {'currentNumber': orderNumber});
        }
      });

      return orderNumber;
    } catch (e) {
      debugPrint('Error getting next order number: $e');

      // Fallback to a timestamp-based number in case of error
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return timestamp % 10000; // Use last 4 digits as a fallback
    }
  }

  // Get all orders
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

  // Get order by id
  Future<OrderModel?> getOrderById(String id) async {
    final doc = await _ordersRef.doc(id).get();

    if (!doc.exists) return null;

    return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Update order status
  Future<void> updateOrderStatus(String id, String status) async {
    await _ordersRef.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  // Get orders by date range
  Future<List<OrderModel>> getOrdersByDateRange(
      DateTime startDate,
      DateTime endDate
      ) async {
    // Convert dates to Firestore timestamps
    final start = Timestamp.fromDate(startDate);
    final end = Timestamp.fromDate(endDate.add(Duration(days: 1)));

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

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics() async {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfWeek = startOfToday.subtract(
        Duration(days: today.weekday - 1)
    );
    final startOfMonth = DateTime(today.year, today.month, 1);

    // Get orders for today
    final todayOrders = await getOrdersByDateRange(
        startOfToday, today
    );

    // Get orders for this week
    final weekOrders = await getOrdersByDateRange(
        startOfWeek, today
    );

    // Get orders for this month
    final monthOrders = await getOrdersByDateRange(
        startOfMonth, today
    );

    // Calculate statistics
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

  // Helper: Calculate total amount from orders
  double _calculateTotal(List<OrderModel> orders) {
    return orders.fold(0, (sum, order) => sum + order.totalAmount);
  }

  // Delete order
  Future<void> deleteOrder(String id) async {
    await _ordersRef.doc(id).delete();
  }
}
import 'package:flutter/material.dart';

// Auth Screens
import 'package:foodkie_express/screens/auth/splash_screen.dart';
import 'package:foodkie_express/screens/auth/login_screen.dart';
import 'package:foodkie_express/screens/auth/otp_screen.dart';
import 'package:foodkie_express/screens/home/controllers/order_details_screen.dart';

// Home Screens
import 'package:foodkie_express/screens/home/home_screen.dart';
import 'package:foodkie_express/screens/home/menu_screen.dart';
import 'package:foodkie_express/screens/home/cart_screen.dart';
import 'package:foodkie_express/screens/home/order_history_screen.dart';
import 'package:foodkie_express/screens/home/profile_screen.dart';

// Menu Management Screens
import 'package:foodkie_express/screens/menu_management/add_item_screen.dart';
import 'package:foodkie_express/screens/menu_management/edit_item_screen.dart';
import 'package:foodkie_express/screens/menu_management/category_management_screen.dart';

// Models (for route arguments)
import 'package:foodkie_express/models/item.dart';
import 'package:foodkie_express/models/category.dart';
import 'package:foodkie_express/models/order.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String menu = '/menu';
  static const String cart = '/cart';
  static const String orderHistory = '/order-history';
  static const String profile = '/profile';
  static const String addItem = '/add-item';
  static const String editItem = '/edit-item';
  static const String categoryManagement = '/category-management';
  static const String orderDetails = '/order-details';

  // Navigation methods
  static Future<void> navigateToHome() async {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(home, (route) => false);
  }

  static Future<void> navigateToLogin() async {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(login, (route) => false);
  }

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case otp:
        final args = settings.arguments as Map<String, dynamic>?;
        final phoneNumber = args?['phoneNumber'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => OTPScreen(phoneNumber: phoneNumber),
        );

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case menu:
        final args = settings.arguments as Map<String, dynamic>?;
        final categoryId = args?['categoryId'] as String?;
        return MaterialPageRoute(
          builder: (_) => MenuScreen(categoryId: categoryId),
        );

      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());

      case orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistoryScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case addItem:
        final args = settings.arguments as Map<String, dynamic>?;
        final categoryId = args?['categoryId'] as String?;
        return MaterialPageRoute(
          builder: (_) => AddItemScreen(categoryId: categoryId),
        );

      case editItem:
        final args = settings.arguments as Map<String, dynamic>?;
        final item = args?['item'] as MenuItemModel;
        return MaterialPageRoute(
          builder: (_) => EditItemScreen(item: item),
        );

      case categoryManagement:
        return MaterialPageRoute(
          builder: (_) => const CategoryManagementScreen(),
        );

      case orderDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final orderId = args?['orderId'] as String?;
        return MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: orderId),
        );

      default:
      // If the route is not found, show an error page
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text('Page not found!'),
            ),
          ),
        );
    }
  }
}

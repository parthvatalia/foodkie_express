class AppConstants {
  // App Info
  static const String appName = 'Foodkie Express';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String categoriesCollection = 'categories';
  static const String menuItemsCollection = 'menuItems';
  static const String ordersCollection = 'orders';

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusProcessing = 'processing';
  static const String orderStatusCompleted = 'completed';
  static const String orderStatusCancelled = 'cancelled';

  // Shared Preferences Keys
  static const String prefsThemeModeKey = 'theme_mode';
  static const String prefsUserIdKey = 'user_id';
  static const String prefsVerificationIdKey = 'verification_id';

  // Error Messages
  static const String errorDefaultMessage = 'Something went wrong. Please try again.';
  static const String errorNetworkMessage = 'Network error. Please check your connection.';
  static const String errorAuthMessage = 'Authentication failed. Please try again.';

  // Success Messages
  static const String successProfileSaved = 'Profile saved successfully';
  static const String successOrderPlaced = 'Order placed successfully';
  static const String successItemAdded = 'Item added successfully';
  static const String successItemUpdated = 'Item updated successfully';

  // Asset Paths
  static const String logoPath = 'assets/images/logo.png';
  static const String splashAnimationPath = 'assets/animations/food_delivery.json';
  static const String emptyCartAnimationPath = 'assets/animations/empty_cart.json';
  static const String orderSuccessAnimationPath = 'assets/animations/order_success.json';
}
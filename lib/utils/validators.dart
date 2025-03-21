class Validators {
  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Basic phone validation - should have 8-15 digits
    final cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedValue.length < 8 || cleanedValue.length > 15) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  // Price validation
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }

    final priceRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!priceRegex.hasMatch(value)) {
      return 'Enter a valid price (e.g., 10.99)';
    }

    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Price must be greater than zero';
    }

    return null;
  }

  // Quantity validation
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }

    final quantity = int.tryParse(value);
    if (quantity == null || quantity <= 0) {
      return 'Quantity must be a positive number';
    }

    return null;
  }
}
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  BluetoothConnection? _connection;
  StreamSubscription? _connectionStateSubscription;

  // Save Bluetooth printer address
  Future<void> saveBluetoothPrinter(String address, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bt_printer_address', address);
    await prefs.setString('bt_printer_name', name);
  }

  // Get saved Bluetooth printer settings
  Future<Map<String, String>?> getSavedBluetoothPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('bt_printer_address');
    final name = prefs.getString('bt_printer_name');

    if (address == null || name == null) return null;

    return {
      'address': address,
      'name': name,
    };
  }

  // Comprehensive Bluetooth permission request
  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      // Request multiple permissions
      final permissionStatuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      // Check if all permissions are granted
      return permissionStatuses.values.every((status) => status.isGranted);
    }
    return true; // For iOS or other platforms
  }

  // Bluetooth availability check with more robust error handling
  Future<bool> isBluetoothEnabled() async {
    try {
      await requestBluetoothPermissions();
      return await FlutterBluetoothSerial.instance.isEnabled ?? false;
    } catch (e) {
      debugPrint('Bluetooth availability check failed: $e');
      return false;
    }
  }

  // Enhanced device discovery
  Future<List<BluetoothDevice>> getAvailableBluetoothDevices() async {
    try {
      // Ensure permissions are granted
      bool permissionsGranted = await requestBluetoothPermissions();
      if (!permissionsGranted) {
        debugPrint('Bluetooth permissions not granted');
        return [];
      }

      // Get bonded devices with timeout
      return await FlutterBluetoothSerial.instance
          .getBondedDevices()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error getting Bluetooth devices: $e');
      return [];
    }
  }

  // Bluetooth enable request with feedback
  Future<bool> requestEnableBluetooth() async {
    try {
      await FlutterBluetoothSerial.instance.requestEnable();
      return await isBluetoothEnabled();
    } catch (e) {
      debugPrint('Bluetooth enable request failed: $e');
      return false;
    }
  }

  // Robust printer connection check
  Future<bool> isPrinterConnected() async {
    final printerInfo = await getSavedBluetoothPrinter();
    if (printerInfo == null) return false;

    try {
      // Attempt to establish a connection with a timeout
      final connection = await BluetoothConnection.toAddress(printerInfo['address']!)
          .timeout(const Duration(seconds: 5));

      // If connection is successful, immediately close it
       connection.dispose();
      return true;
    } on TimeoutException {
      debugPrint('Printer connection timeout');
      return false;
    } catch (e) {
      debugPrint('Printer connection check failed: $e');
      return false;
    }
  }

  // Advanced print method with retry and error handling
  Future<bool> printReceipt(Map<String, dynamic> data, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      BluetoothConnection? connection;
      try {
        // Validate printer configuration
        final printerInfo = await getSavedBluetoothPrinter();
        if (printerInfo == null) {
          debugPrint('No Bluetooth printer configured');
          return false;
        }

        // Establish connection with robust error handling
        connection = await BluetoothConnection.toAddress(printerInfo['address']!)
            .timeout(const Duration(seconds: 10));

        // Prepare print commands with more robust ESC/POS commands
        List<int> commands = _preparePrintCommands(data);

        // Send initialization commands
        _sendInitializationCommands(connection);

        // Send data with chunking to prevent buffer overflow
        await _sendDataInChunks(connection, commands);

        // Send cut and feed commands
        _sendCutPaperCommands(connection);

        // Close connection
        connection.dispose();

        return true;
      } on TimeoutException {
        debugPrint('Printer connection timeout (Attempt $attempt)');
      } catch (e) {
        debugPrint('Printer error (Attempt $attempt): $e');
      } finally {
        connection?.dispose();
      }

      // Wait before retrying
      await Future.delayed(const Duration(seconds: 2));
    }

    return false;
  }

  // Send initialization commands
  void _sendInitializationCommands(BluetoothConnection connection) {
    final initCommands = [
      0x1B, 0x40,   // ESC @ - Initialize printer
      0x1B, 0x4D, 0x00, // Select character code table
      0x1B, 0x21, 0x00, // Cancel bold, underline, double-height, double-width
    ];
    connection.output.add(Uint8List.fromList(initCommands));
  }

  // Send paper cut and feed commands
  void _sendCutPaperCommands(BluetoothConnection connection) {
    final cutCommands = [
      0x0A, 0x0A, 0x0A, // Feed 3 lines
      0x1D, 0x56, 0x01  // Partial cut
    ];
    connection.output.add(Uint8List.fromList(cutCommands));
  }

  // Chunk data sending to prevent buffer overflow
  Future<void> _sendDataInChunks(BluetoothConnection connection, List<int> data, {int chunkSize = 256}) async {
    for (int i = 0; i < data.length; i += chunkSize) {
      final chunk = data.sublist(
          i,
          i + chunkSize > data.length ? data.length : i + chunkSize
      );
      connection.output.add(Uint8List.fromList(chunk));
      await connection.output.allSent;

      // Small delay to prevent overwhelming the printer
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  // Comprehensive print command preparation
  List<int> _preparePrintCommands(Map<String, dynamic> data) {
    List<int> commands = [];

    // ESC/POS command constants
    const ESC = 0x1B;
    const GS = 0x1D;
    const LF = 0x0A;

    // Text alignment commands
    final centerAlign = [ESC, 0x61, 0x01]; // Center alignment
    final leftAlign = [ESC, 0x61, 0x00];   // Left alignment

    // Font modifications
    final normalFont = [ESC, 0x21, 0x00];  // Normal font
    final boldFont = [ESC, 0x21, 0x08];    // Bold font
    final doubleHeight = [ESC, 0x21, 0x10]; // Double height

    // Add center alignment and bold font for header
    commands.addAll(centerAlign);
    commands.addAll(boldFont);

    // Restaurant details
    final restaurantName = (data['restaurant']?['name'] ?? 'Foodkie Express').toUpperCase();
    commands.addAll(utf8.encode(restaurantName));
    commands.add(LF);

    // Reset to normal font
    commands.addAll(normalFont);

    // Order details
    final orderNumber = data['orderNumber'] ?? 'N/A';
    final timestamp = data['timestamp'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(data['timestamp']))
        : DateTime.now().toString();

    commands.addAll(utf8.encode('Order #: $orderNumber'));
    commands.add(LF);
    commands.addAll(utf8.encode('Date: $timestamp'));
    commands.add(LF);

    // Separator
    commands.addAll(utf8.encode('--------------------------------'));
    commands.add(LF);

    // Items
    final items = data['items'] ?? [];
    for (var item in items) {
      final name = item['name'] ?? 'Unknown Item';
      final quantity = item['quantity'] ?? 1;
      final price = item['price'] ?? 0.0;
      final total = quantity * price;

      final itemLine = '$quantity x $name';
      commands.addAll(utf8.encode(itemLine));
      commands.add(LF);
      commands.addAll(utf8.encode('Price: ₹${total.toStringAsFixed(2)}'));
      commands.add(LF);
    }

    // Separator
    commands.addAll(utf8.encode('--------------------------------'));
    commands.add(LF);

    // Total
    final total = data['total'] ?? 0.0;
    commands.addAll(boldFont);
    commands.addAll(utf8.encode('TOTAL: ₹${total.toStringAsFixed(2)}'));
    commands.add(LF);

    // Reset to normal font and left alignment
    commands.addAll(normalFont);
    commands.addAll(leftAlign);

    return commands;
  }

  // Test print method
  Future<bool> printTest() async {
    try {
      // Prepare a comprehensive test receipt
      final testData = {
        'items': [
          {'name': 'Test Item 1', 'quantity': 2, 'price': 10.50},
          {'name': 'Test Item 2', 'quantity': 1, 'price': 15.75}
        ],
        'total': 36.75,
        'timestamp': DateTime.now().toString(),
        'restaurant': {
          'name': 'Foodkie Express',
          'address': 'Test Address'
        },
        'orderNumber': 'TEST-001'
      };

      return await printReceipt(testData);
    } catch (e) {
      debugPrint('Test print failed: $e');
      return false;
    }
  }
}
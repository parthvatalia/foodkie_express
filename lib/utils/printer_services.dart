import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert' show ascii;
import 'bluetooth_service.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();

  factory PrinterService() => _instance;

  PrinterService._internal();

  // Reference to our custom BluetoothService
  final BluetoothService _bluetoothService = BluetoothService();

  // Save printer info to SharedPreferences
  Future<void> saveBluetoothPrinter(String address, String name) async {
    await _bluetoothService.savePrinter(address, name);
  }

  // Get saved printer from SharedPreferences
  Future<Map<String, String>?> getSavedBluetoothPrinter() async {
    return await _bluetoothService.getSavedPrinter();
  }

  // Request all necessary Bluetooth permissions based on platform and Android version
  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      List<Permission> permissions = [];

      // Request appropriate permissions based on Android version
      if (Platform.isAndroid) {
        if (await Permission.bluetoothScan.status.isDenied) {
          permissions.add(Permission.bluetoothScan);
        }
        if (await Permission.bluetoothConnect.status.isDenied) {
          permissions.add(Permission.bluetoothConnect);
        }
        if (await Permission.bluetooth.status.isDenied) {
          permissions.add(Permission.bluetooth);
        }

        // Location needed for Bluetooth scanning on older Android
        if (await Permission.location.status.isDenied) {
          permissions.add(Permission.location);
        }
      }

      if (permissions.isNotEmpty) {
        final statuses = await permissions.request();
        return statuses.values.every((status) => status.isGranted);
      }
      return true;
    }
    return true; // For iOS or other platforms
  }

  // Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      await requestBluetoothPermissions();
      return await _bluetoothService.isEnabled();
    } catch (e) {
      debugPrint('Bluetooth availability check failed: $e');
      return false;
    }
  }

  // Get list of paired Bluetooth devices
  Future<List<BluetoothDevice>> getAvailableBluetoothDevices() async {
    try {
      bool permissionsGranted = await requestBluetoothPermissions();
      if (!permissionsGranted) {
        debugPrint('Bluetooth permissions not granted');
        return [];
      }

      return await _bluetoothService.getBondedDevices();
    } catch (e) {
      debugPrint('Error getting Bluetooth devices: $e');
      return [];
    }
  }

  // Request user to enable Bluetooth
  Future<bool> requestEnableBluetooth() async {
    try {
      await _bluetoothService.requestEnable();
      return await isBluetoothEnabled();
    } catch (e) {
      debugPrint('Bluetooth enable request failed: $e');
      return false;
    }
  }

  // Check if the saved printer is connected
  Future<bool> isPrinterConnected() async {
    final printerInfo = await getSavedBluetoothPrinter();
    if (printerInfo == null) return false;

    try {
      // First check if BT is enabled
      bool enabled = await isBluetoothEnabled();
      if (!enabled) return false;

      // Test connection to the saved printer
      bool connected = await _bluetoothService.connect(printerInfo['address']!);
      if (connected) {
        await _bluetoothService.disconnect(); // Just testing the connection
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Printer connection check failed: $e');
      return false;
    }
  }

  // Print receipt with retry mechanism
  Future<bool> printReceipt(
    Map<String, dynamic> data, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final printerInfo = await getSavedBluetoothPrinter();
        if (printerInfo == null) {
          debugPrint('No Bluetooth printer configured');
          return false;
        }

        // Connect to printer
        bool connected = await _bluetoothService.connect(
          printerInfo['address']!,
        );
        if (!connected) {
          debugPrint('Failed to connect to printer (Attempt $attempt)');
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        // Prepare print commands
        List<int> commands = _preparePrintCommands(data);

        // Send data to printer
        bool sent = await _bluetoothService.write(Uint8List.fromList(commands));

        // Disconnect
        await _bluetoothService.disconnect();

        if (sent) {
          return true;
        } else {
          debugPrint('Failed to send data to printer (Attempt $attempt)');
        }
      } catch (e) {
        debugPrint('Printer error (Attempt $attempt): $e');
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    return false;
  }

  // Prepare ESC/POS commands for printing
  List<int> _preparePrintCommands(Map<String, dynamic> data) {
    List<int> commands = [];

    const ESC = 0x1B;
    const GS = 0x1D;
    const LF = 0x0A;

    // Initialize printer
    commands.addAll([ESC, 0x40]); // Initialize printer

    // Text alignment commands
    final centerAlign = [ESC, 0x61, 0x01]; // Center align
    final leftAlign = [ESC, 0x61, 0x00]; // Left align

    // Text formatting commands
    final normalFont = [ESC, 0x21, 0x00]; // Normal font
    final boldOn = [ESC, 0x45, 0x01]; // Bold on
    final boldOff = [ESC, 0x45, 0x00]; // Bold off

    // Start with center alignment and bold for header
    commands.addAll(centerAlign);
    commands.addAll(boldOn);

    // Restaurant name
    final restaurantName =
        (data['restaurant']?['name'] ?? 'Foodkie Express').toUpperCase();
    commands.addAll(ascii.encode(restaurantName));
    commands.add(LF);

    // Restaurant address
    if (data['restaurant']?['address'] != null) {
      commands.addAll(ascii.encode(data['restaurant']['address']));
      commands.add(LF);
    }

    // Restaurant phone
    if (data['restaurant']?['phone'] != null) {
      commands.addAll(ascii.encode(data['restaurant']['phone']));
      commands.add(LF);
    }

    commands.addAll(boldOff);
    commands.add(LF);

    // Order information
    final orderNumber = data['orderNumber'] ?? 'N/A';
    final timestamp =
        data['timestamp'] != null
            ? DateFormat(
              'dd/MM/yyyy HH:mm aa',
            ).format(DateTime.parse(data['timestamp']))
            : DateFormat('dd/MM/yyyy HH:mm aa').format(DateTime.now());

    final orderLine =
        'ORDER : $orderNumber'.padRight(20) + timestamp.padLeft(12);
    commands.addAll(ascii.encode(orderLine));
    commands.add(LF);

    // Customer information
    final customerName = data['customerName'] ?? '';
    if (customerName.toString().isNotEmpty) {
      commands.addAll(ascii.encode('CUSTOMER : $customerName'));
      commands.add(LF);
    }

    final customerPhone = data['customerPhone'] ?? '';
    final notesAll = data['notes'] ?? '';
    if (customerPhone.toString().isNotEmpty) {
      commands.addAll(ascii.encode('PHONE : $customerPhone'));
      commands.add(LF);
    }

    // Separator line
    commands.addAll(ascii.encode(''.padRight(42, '-')));
    commands.add(LF);
    commands.add(LF);

    const int lineWidth = 42;

    // Order items
    final items = data['items'] ?? [];
    for (var item in items) {
      final name = item['name'] ?? 'Unknown Item';
      final quantity = item['quantity'] ?? 1;
      final notes = item['notes'] ?? '';
      final price = item['price'] ?? 0.0;
      final total = quantity * price;

      final quantityStr = '$quantity';
      final nameStr = name.toUpperCase();
      final priceStr = 'Rs.${total.toStringAsFixed(2)}';

      final itemText = '$quantityStr x $nameStr';
      final spacesNeeded = lineWidth - itemText.length - priceStr.length;
      final spaces = ' ' * (spacesNeeded > 0 ? spacesNeeded : 1);

      final formattedLine = itemText + spaces + priceStr;
      commands.addAll(ascii.encode(formattedLine));

      // Add item notes if any
      if (notes.toString().isNotEmpty) {
        commands.add(LF);
        commands.addAll(leftAlign);
        commands.addAll(ascii.encode('note: $notes'));
        commands.addAll(centerAlign);
        commands.add(LF);
      }
      commands.add(LF);
    }

    // Separator line
    commands.addAll(ascii.encode(''.padRight(lineWidth, '-')));

    // Order notes if any
    if (notesAll.toString().isNotEmpty) {
      commands.add(LF);
      commands.addAll(leftAlign);
      commands.addAll(ascii.encode('note: $notesAll'));
      commands.addAll(centerAlign);
      commands.add(LF);
      commands.addAll(ascii.encode(''.padRight(lineWidth, '-')));
    }
    commands.add(LF);

    // Total amount
    commands.addAll(boldOn);
    final total = data['total'] ?? 0.0;

    const totalText = 'TOTAL:';
    final totalValue = 'Rs.${total.toStringAsFixed(2)}';
    final totalSpaces = lineWidth - totalText.length - totalValue.length;
    commands.addAll(
      ascii.encode(totalText + ' '.padRight(totalSpaces) + totalValue),
    );
    commands.addAll(boldOff);
    commands.add(LF);

    // Payment method
    final paymentMethod = data['paymentMethod'] ?? 'CASH';
    const transactionType = 'TRANSACTION TYPE:';
    final transactionTypeValue = '$paymentMethod';
    final transactionTypeTotalSpaces =
        lineWidth - transactionType.length - transactionTypeValue.length;
    commands.addAll(
      ascii.encode(
        transactionType +
            ' '.padRight(transactionTypeTotalSpaces) +
            transactionTypeValue,
      ),
    );
    commands.add(LF);
    commands.add(LF);
    commands.add(LF);

    // Footer
    commands.addAll(centerAlign);
    commands.addAll(ascii.encode('CUSTOMER COPY'));
    commands.add(LF);
    commands.addAll(ascii.encode('THANKS FOR VISITING'));
    commands.add(LF);
    commands.addAll(ascii.encode('POWERED BY FOODKIE EXPRESS'));
    commands.add(LF);
    commands.add(LF);

    // Feed and cut paper
    commands.addAll([LF, LF, LF, LF]);
    commands.addAll([GS, 0x56, 0x00]); // Cut paper command

    return commands;
  }

  // Print a test receipt
  Future<bool> printTest() async {
    try {
      final testData = {
        'items': [
          {'name': 'Test Item 1', 'quantity': 2, 'price': 10.50},
          {'name': 'Test Item 2', 'quantity': 1, 'price': 15.75},
        ],
        'total': 36.75,
        'timestamp': DateTime.now().toString(),
        'restaurant': {'name': 'Foodkie Express', 'address': 'Test Address'},
        'orderNumber': 'TEST-001',
        'paymentMethod': 'CASH',
      };

      return await printReceipt(testData);
    } catch (e) {
      debugPrint('Test print failed: $e');
      return false;
    }
  }
}

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

  Future<bool> requestBluetoothPermissions() async {
    // For Android 12+
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      // Check if all permissions are granted
      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (status != PermissionStatus.granted) {
          allGranted = false;
        }
      });

      return allGranted;
    }

    // For iOS or older Android versions
    return true;
  }

  Future<bool> isBluetoothEnabled() async {
    await requestBluetoothPermissions();
    return await FlutterBluetoothSerial.instance.isEnabled ?? false;
  }

  Future<List<BluetoothDevice>> getAvailableBluetoothDevices() async {
    try {
      // Request permissions first
      bool permissionsGranted = await requestBluetoothPermissions();
      if (!permissionsGranted) {
        debugPrint('Bluetooth permissions not granted');
        return [];
      }

      // Get bonded Bluetooth devices
      FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      return devices;
    } catch (e) {
      debugPrint('Error getting Bluetooth devices: $e');
      return [];
    }
  }

  // Request to enable Bluetooth
  Future<bool> requestEnableBluetooth() async {
    await FlutterBluetoothSerial.instance.requestEnable();
    return await isBluetoothEnabled();
  }

  // Check if printer is connected
  Future<bool> isPrinterConnected() async {
    final printerInfo = await getSavedBluetoothPrinter();
    if (printerInfo == null) return false;

    try {
      // Try to establish a connection
      BluetoothConnection connection = await BluetoothConnection.toAddress(
        printerInfo['address']!,
      );
      await Future.delayed(const Duration(milliseconds: 500));

      // If we get here, connection was successful
      connection.dispose();
      return true;
    } catch (e) {
      debugPrint('Printer connection check failed: $e');
      return false;
    }
  }

  // Print receipt via Bluetooth
  Future<bool> printReceipt(Map<String, dynamic> data) async {
    try {
      // Get printer address
      final printerInfo = await getSavedBluetoothPrinter();
      if (printerInfo == null) {
        debugPrint('No Bluetooth printer configured');
        return false;
      }

      final printerAddress = printerInfo['address']!;

      // Prepare receipt data
      final items = data['items'] as List<dynamic>;
      final total = data['total'] as double;
      final notes = data['notes'] as String?;
      final timestamp = data['timestamp'] as String;
      final orderNumber = data['orderNumber'] as String?;

      // Get restaurant info
      final restaurant = data['restaurant'] as Map<String, dynamic>?;
      final restaurantName = restaurant?['name'] as String? ?? 'FOODKIE EXPRESS';
      final restaurantAddress = restaurant?['address'] as String? ?? '';

      // Calculate subtotal
      final subtotal = items.fold<double>(
        0,
            (sum, item) => sum + (item['price'] as double) * (item['quantity'] as int),
      );

      // ESC/POS Commands for Centering
      const ESC = 0x1B;
      const LF = 0x0A;
      const TEXT_ALIGN_CENTER = [ESC, 0x61, 0x01]; // Center alignment

      List<int> commands = [];

      // Reset printer
      commands.addAll([ESC, 0x40]);

      // Center align everything
      commands.addAll(TEXT_ALIGN_CENTER);

      // Restaurant name
      commands.addAll(utf8.encode(restaurantName));
      commands.add(LF);

      // Restaurant address
      if (restaurantAddress.isNotEmpty) {
        commands.addAll(utf8.encode(restaurantAddress));
        commands.add(LF);
      }

      // Order details
      commands.addAll(utf8.encode("ORDER #: ${orderNumber ?? '---'}"));
      commands.add(LF);

      // Date
      String dateStr = DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.parse(timestamp));
      commands.addAll(utf8.encode(dateStr));
      commands.add(LF);

      // Separator
      commands.addAll(utf8.encode("--------------------------------"));
      commands.add(LF);

      // Process items (centered)
      for (var item in items) {
        final name = (item['name'] as String);
        final price = item['price'] as double;
        final quantity = item['quantity'] as int;
        final itemTotal = quantity * price;

        String itemLine = "$quantity x $name";
        commands.addAll(utf8.encode(itemLine));
        commands.add(LF);

        String priceLine = "Rs. ${itemTotal.toStringAsFixed(2)}";
        commands.addAll(utf8.encode(priceLine));
        commands.add(LF);
      }

      // Separator
      commands.addAll(utf8.encode("--------------------------------"));
      commands.add(LF);

      // Totals (centered)
      commands.addAll(utf8.encode("SUBTOTAL: Rs. ${subtotal.toStringAsFixed(2)}"));
      commands.add(LF);

      commands.addAll(utf8.encode("TOTAL: Rs. ${total.toStringAsFixed(2)}"));
      commands.add(LF);

      // Notes if any
      if (notes != null && notes.isNotEmpty) {
        commands.add(LF);
        commands.addAll(utf8.encode("Notes: $notes"));
        commands.add(LF);
      }

      // Footer
      commands.add(LF);
      commands.addAll(utf8.encode("THANK YOU FOR YOUR ORDER"));
      commands.add(LF);
      commands.addAll(utf8.encode("POWERED BY FOODKIE EXPRESS"));

      // Extra line feeds
      commands.add(LF);
      commands.add(LF);
      commands.add(LF);
      commands.add(LF);

      // Connect to printer
      debugPrint('Connecting to printer: $printerAddress');
      final connection = await BluetoothConnection.toAddress(printerAddress);
      debugPrint('Connected to printer');
      await Future.delayed(const Duration(milliseconds: 500));

      // Send data
      connection.output.add(Uint8List.fromList(commands));
      await connection.output.allSent;

      // Close connection
      await Future.delayed(const Duration(seconds: 1));
      connection.dispose();

      return true;
    } catch (e) {
      debugPrint('Error printing: $e');
      return false;
    }
  }

  // Text wrapping utility method
  List<String> _wrapText(String text, int width) {
    List<String> lines = [];

    while (text.length > width) {
      // Find the last space before width limit
      int spaceIndex = text.substring(0, width).lastIndexOf(' ');

      if (spaceIndex == -1) {
        // No space found, force break at width
        lines.add(text.substring(0, width));
        text = text.substring(width);
      } else {
        // Break at the last space
        lines.add(text.substring(0, spaceIndex));
        text = text.substring(spaceIndex + 1);
      }
    }

    // Add the remaining text
    if (text.isNotEmpty) {
      lines.add(text);
    }

    return lines;
  }

  // Test print method with centered content
  Future<bool> printTest() async {
    try {
      // Check Bluetooth status
      bool bluetoothEnabled = await isBluetoothEnabled();
      if (!bluetoothEnabled) {
        debugPrint('Bluetooth is not enabled');
        return false;
      }

      // Get printer info
      final printerInfo = await getSavedBluetoothPrinter();
      if (printerInfo == null) {
        debugPrint('No Bluetooth printer configured');
        return false;
      }

      final printerAddress = printerInfo['address']!;

      // ESC/POS Commands
      const ESC = 0x1B;
      const GS = 0x1D;
      const LF = 0x0A;
      const TEXT_ALIGN_CENTER = [ESC, 0x61, 0x01]; // Center alignment
      const RESET = [ESC, 0x40]; // Reset printer
      const CUT = [GS, 0x56, 0x00]; // Paper cut

      // Create command buffer
      List<int> commands = [];

      // Reset and center align
      commands.addAll(RESET);
      commands.addAll(TEXT_ALIGN_CENTER);

      // Test header (centered)
      commands.addAll(utf8.encode('PRINTER TEST'));
      commands.add(LF);

      // Date/time (centered)
      commands.addAll(utf8.encode(DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.now())));
      commands.add(LF);
      commands.add(LF);

      // Centered test messages
      commands.addAll(utf8.encode('If this prints with proper'));
      commands.add(LF);
      commands.addAll(utf8.encode('center alignment,'));
      commands.add(LF);
      commands.addAll(utf8.encode('your printer is configured correctly'));
      commands.add(LF);

      // Separator
      commands.addAll(utf8.encode('--------------------------------'));
      commands.add(LF);

      // Extra feeds and cut
      commands.add(LF);
      commands.add(LF);
      commands.addAll(CUT);

      // Connect to printer
      debugPrint('Connecting to printer for test: $printerAddress');
      BluetoothConnection connection = await BluetoothConnection.toAddress(printerAddress);
      await Future.delayed(const Duration(milliseconds: 500));

      // Send data
      connection.output.add(Uint8List.fromList(commands));
      await connection.output.allSent;

      // Close connection
      connection.dispose();

      return true;
    } catch (e) {
      debugPrint('Error printing test via Bluetooth: $e');
      return false;
    }
  }
}
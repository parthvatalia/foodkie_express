import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert' show ascii;

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();

  factory PrinterService() => _instance;

  PrinterService._internal();

  Future<void> saveBluetoothPrinter(String address, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bt_printer_address', address);
    await prefs.setString('bt_printer_name', name);
  }

  Future<Map<String, String>?> getSavedBluetoothPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('bt_printer_address');
    final name = prefs.getString('bt_printer_name');

    if (address == null || name == null) return null;

    return {'address': address, 'name': name};
  }

  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final permissionStatuses =
          await [
            Permission.bluetooth,
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.location,
          ].request();

      return permissionStatuses.values.every((status) => status.isGranted);
    }
    return true;
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      await requestBluetoothPermissions();
      return await FlutterBluetoothSerial.instance.isEnabled ?? false;
    } catch (e) {
      debugPrint('Bluetooth availability check failed: $e');
      return false;
    }
  }

  
  Future<List<BluetoothDevice>> getAvailableBluetoothDevices() async {
    try {
      bool permissionsGranted = await requestBluetoothPermissions();
      if (!permissionsGranted) {
        debugPrint('Bluetooth permissions not granted');
        return [];
      }

      return await FlutterBluetoothSerial.instance.getBondedDevices().timeout(
        const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error getting Bluetooth devices: $e');
      return [];
    }
  }

  Future<bool> requestEnableBluetooth() async {
    try {
      await FlutterBluetoothSerial.instance.requestEnable();
      return await isBluetoothEnabled();
    } catch (e) {
      debugPrint('Bluetooth enable request failed: $e');
      return false;
    }
  }

  Future<bool> isPrinterConnected() async {
    final printerInfo = await getSavedBluetoothPrinter();
    if (printerInfo == null) return false;

    try {
      final connection = await BluetoothConnection.toAddress(
        printerInfo['address']!,
      ).timeout(const Duration(seconds: 5));

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

  Future<bool> printReceipt(
    Map<String, dynamic> data, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      BluetoothConnection? connection;
      try {
        final printerInfo = await getSavedBluetoothPrinter();
        if (printerInfo == null) {
          debugPrint('No Bluetooth printer configured');
          return false;
        }

        connection = await BluetoothConnection.toAddress(
          printerInfo['address']!,
        ).timeout(const Duration(seconds: 10));

        List<int> commands = _preparePrintCommands(data);

        _sendInitializationCommands(connection);

        await _sendDataInChunks(connection, commands);
        await Future.delayed(const Duration(seconds: 1));

        

        connection.dispose();

        return true;
      } on TimeoutException {
        debugPrint('Printer connection timeout (Attempt $attempt)');
      } catch (e) {
        debugPrint('Printer error (Attempt $attempt): $e');
      } finally {
        connection?.dispose();
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    return false;
  }

  void _sendInitializationCommands(BluetoothConnection connection) {
    final initCommands = [
      0x1B, 0x40, 
      0x1B, 0x4D, 0x00, 
      0x1B, 0x21, 0x00, 
    ];
    connection.output.add(Uint8List.fromList(initCommands));
  }

  void _sendCutPaperCommands(BluetoothConnection connection) {
    final cutCommands = [
      0x0A, 0x0A, 0x0A, 
      0x1D, 0x56, 0x01, 
    ];
    connection.output.add(Uint8List.fromList(cutCommands));
  }

  Future<void> _sendDataInChunks(
    BluetoothConnection connection,
    List<int> data, {
    int chunkSize = 128,
  }) async {
    for (int i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      final chunk = data.sublist(i, end);

      connection.output.add(Uint8List.fromList(chunk));
      await connection.output.allSent;

      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  List<int> _preparePrintCommands(Map<String, dynamic> data) {
    List<int> commands = [];

    const ESC = 0x1B;
    const GS = 0x1D;
    const LF = 0x0A;

    commands.addAll([ESC, 0x40]); 

    final centerAlign = [ESC, 0x61, 0x01]; 

    final normalFont = [ESC, 0x21, 0x00]; 
    final boldOn = [ESC, 0x45, 0x01]; 
    final boldOff = [ESC, 0x45, 0x00]; 

    commands.addAll(centerAlign);
    commands.addAll(boldOn);

    final restaurantName =
        (data['restaurant']?['name'] ?? 'Foodkie Express').toUpperCase();
    commands.addAll(ascii.encode(restaurantName));
    commands.add(LF);

    if (data['restaurant']?['address'] != null) {
      commands.addAll(ascii.encode(data['restaurant']['address']));
      commands.add(LF);
    }

    if (data['restaurant']?['phone'] != null) {
      commands.addAll(ascii.encode(data['restaurant']['phone']));
      commands.add(LF);
    }

    commands.addAll(boldOff);
    commands.add(LF);

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

    final customerName = data['customerName'] ?? 'N/A';
    commands.addAll(ascii.encode('CUSTOMER : $customerName'));
    commands.add(LF);

    final customerPhone = data['customerPhone'] ?? 'N/A';
    commands.addAll(ascii.encode('PHONE : $customerPhone'));
    commands.add(LF);

    commands.addAll(ascii.encode(''.padRight(42, '-')));
    commands.add(LF);
    commands.add(LF);

    const int lineWidth = 42; 

    
    final items = data['items'] ?? [];
    for (var item in items) {
      final name = item['name'] ?? 'Unknown Item';
      final quantity = item['quantity'] ?? 1;
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
      commands.add(LF);
    }

    commands.addAll(ascii.encode(''.padRight(lineWidth, '-')));
    commands.add(LF);

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
    final paymentMethod = data['paymentMethod'] ?? 'CASH';

    const tansactionType = 'TRANSACTION TYPE:';
    final tansactionTypeValue = '$paymentMethod';
    final tansactionTypeTotalSpaces =
        lineWidth - tansactionType.length - tansactionTypeValue.length;
    commands.addAll(
      ascii.encode(
        tansactionType +
            ' '.padRight(tansactionTypeTotalSpaces) +
            tansactionTypeValue,
      ),
    );
    commands.add(LF);
    commands.add(LF);
    commands.add(LF);

    
    commands.addAll(centerAlign);
    commands.addAll(ascii.encode('CUSTOMER COPY'));
    commands.add(LF);
    commands.addAll(ascii.encode('THANKS FOR VISITING'));
    commands.add(LF);
    commands.addAll(ascii.encode('POWERED BY FOODKIE EXPRESS'));
    commands.add(LF);
    commands.add(LF);

    
    commands.addAll([LF, LF, LF, LF]); 
    commands.addAll([GS, 0x56, 0x00]); 

    return commands;
  }

  
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
      };

      return await printReceipt(testData);
    } catch (e) {
      debugPrint('Test print failed: $e');
      return false;
    }
  }
}

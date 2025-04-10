import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();

  factory BluetoothService() => _instance;

  BluetoothService._internal();

  // Method channel for platform communication
  static const MethodChannel _channel = MethodChannel('com.infinite.foodkie.express.foodkie_express/bluetooth');

  // Stream controllers
  final StreamController<bool> _isEnabledController = StreamController.broadcast();
  final StreamController<List<BluetoothDevice>> _devicesController = StreamController.broadcast();
  final StreamController<BluetoothConnectionState> _connectionStateController = StreamController.broadcast();

  // Getters for streams
  Stream<bool> get isEnabledStream => _isEnabledController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;

  // Check if Bluetooth is available
  Future<bool> isAvailable() async {
    try {
      final bool result = await _channel.invokeMethod('isAvailable');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error checking Bluetooth availability: ${e.message}');
      return false;
    }
  }

  // Check if Bluetooth is enabled
  Future<bool> isEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isEnabled');
      _isEnabledController.add(result);
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error checking if Bluetooth is enabled: ${e.message}');
      return false;
    }
  }

  // Request to enable Bluetooth
  Future<bool> requestEnable() async {
    try {
      final bool result = await _channel.invokeMethod('requestEnable');
      _isEnabledController.add(result);
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error requesting Bluetooth enable: ${e.message}');
      return false;
    }
  }

  // Get bonded (paired) devices
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getBondedDevices');
      final devices = result.map((device) => BluetoothDevice.fromMap(device)).toList();
      _devicesController.add(devices);
      return devices;
    } on PlatformException catch (e) {
      debugPrint('Error getting bonded devices: ${e.message}');
      return [];
    }
  }

  // Connect to a device
  Future<bool> connect(String address) async {
    try {
      final bool result = await _channel.invokeMethod('connect', {'address': address});
      if (result) {
        _connectionStateController.add(BluetoothConnectionState.connected);
      }
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error connecting to device: ${e.message}');
      _connectionStateController.add(BluetoothConnectionState.disconnected);
      return false;
    }
  }

  // Disconnect from current device
  Future<bool> disconnect() async {
    try {
      final bool result = await _channel.invokeMethod('disconnect');
      _connectionStateController.add(BluetoothConnectionState.disconnected);
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error disconnecting: ${e.message}');
      return false;
    }
  }

  // Write data to connected device
  Future<bool> write(Uint8List data) async {
    try {
      final bool result = await _channel.invokeMethod('write', {'data': data});
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error writing data: ${e.message}');
      return false;
    }
  }

  // Check if connected to any device
  Future<bool> isConnected() async {
    try {
      final bool result = await _channel.invokeMethod('isConnected');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error checking connection: ${e.message}');
      return false;
    }
  }

  // Save printer info to SharedPreferences
  Future<void> savePrinter(String address, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bt_printer_address', address);
    await prefs.setString('bt_printer_name', name);
  }

  // Get saved printer from SharedPreferences
  Future<Map<String, String>?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('bt_printer_address');
    final name = prefs.getString('bt_printer_name');

    if (address == null || name == null) return null;

    return {'address': address, 'name': name};
  }

  // Dispose resources
  void dispose() {
    _isEnabledController.close();
    _devicesController.close();
    _connectionStateController.close();
  }
}

// Bluetooth device model
class BluetoothDevice {
  final String name;
  final String address;
  final int type;
  final bool isBonded;

  BluetoothDevice({
    required this.name,
    required this.address,
    required this.type,
    required this.isBonded,
  });

  factory BluetoothDevice.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothDevice(
      name: map['name'] ?? 'Unknown Device',
      address: map['address'] ?? '',
      type: map['type'] ?? 0,
      isBonded: map['isBonded'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'type': type,
      'isBonded': isBonded,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BluetoothDevice &&
              runtimeType == other.runtimeType &&
              address == other.address;

  @override
  int get hashCode => address.hashCode;
}

// Connection state enum
enum BluetoothConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error
}
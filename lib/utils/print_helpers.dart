import 'package:flutter/material.dart';
import 'package:foodkie_express/utils/printer_services.dart';

import '../screens/settings/bluetooth_printer_screen.dart';

Future<void> checkAndSetupPrinter(BuildContext context) async {
  final printerService = PrinterService();

  // Check if Bluetooth is enabled
  bool bluetoothEnabled = await printerService.isBluetoothEnabled();
  if (!bluetoothEnabled) {
    bool enabled = await printerService.requestEnableBluetooth();
    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable Bluetooth to use the printer')),
      );
      return;
    }
  }

  // Check if a printer is already configured
  Map<String, String>? savedPrinter = await printerService.getSavedBluetoothPrinter();

  if (savedPrinter != null) {
    // Check if printer is connected
    bool connected = await printerService.isPrinterConnected();

    if (connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Printer ${savedPrinter['name']} is connected'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
  }

  // Show printer selection screen if no printer or printer not connected
  if (context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BluetoothPrinterSelectionScreen(),
      ),
    );
  }
}
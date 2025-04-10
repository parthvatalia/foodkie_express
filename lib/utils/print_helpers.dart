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

  // Check if a printer is already saved
  Map<String, String>? savedPrinter = await printerService.getSavedBluetoothPrinter();

  if (savedPrinter != null) {
    // Try to connect to the saved printer
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

  // If no printer is connected or saved, show the printer selection screen
  if (context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BluetoothPrinterSelectionScreen(),
      ),
    );
  }
}
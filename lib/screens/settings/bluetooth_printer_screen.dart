import 'package:flutter/material.dart';
import 'package:foodkie_express/utils/bluetooth_service.dart';
import 'package:foodkie_express/utils/printer_services.dart';

class BluetoothPrinterSelectionScreen extends StatefulWidget {
  const BluetoothPrinterSelectionScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothPrinterSelectionScreen> createState() => _BluetoothPrinterSelectionScreenState();
}

class _BluetoothPrinterSelectionScreenState extends State<BluetoothPrinterSelectionScreen> {
  final PrinterService _printerService = PrinterService();
  final BluetoothService _bluetoothService = BluetoothService();

  List<BluetoothDevice> _devices = [];
  bool _isLoading = true;
  bool _isScanning = false;
  String? _selectedDeviceAddress;
  String? _connectedDeviceName;
  String? _connectedDeviceAddress;

  @override
  void initState() {
    super.initState();
    _initBluetoothConnection();
  }

  Future<void> _initBluetoothConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Request necessary permissions
      await _printerService.requestBluetoothPermissions();

      // Check if Bluetooth is enabled
      bool isEnabled = await _printerService.isBluetoothEnabled();
      if (!isEnabled) {
        isEnabled = await _printerService.requestEnableBluetooth();
        if (!isEnabled) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Get saved printer info
      final savedPrinter = await _printerService.getSavedBluetoothPrinter();
      if (savedPrinter != null) {
        setState(() {
          _connectedDeviceName = savedPrinter['name'];
          _connectedDeviceAddress = savedPrinter['address'];
          _selectedDeviceAddress = savedPrinter['address'];
        });
      }

      // Load paired devices
      await _refreshDevicesList();
    } catch (e) {
      _showErrorSnackBar('Error initializing Bluetooth: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDevicesList() async {
    setState(() {
      _isScanning = true;
    });

    try {
      // Get paired devices
      final devices = await _printerService.getAvailableBluetoothDevices();
      setState(() {
        _devices = devices;
      });
    } catch (e) {
      _showErrorSnackBar('Error scanning for devices: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Connect to the device
      bool connected = await _bluetoothService.connect(device.address);

      if (connected) {
        // Save the printer info if connection successful
        await _printerService.saveBluetoothPrinter(device.address, device.name);

        setState(() {
          _connectedDeviceName = device.name;
          _connectedDeviceAddress = device.address;
          _selectedDeviceAddress = device.address;
        });

        // Disconnect after testing
        await _bluetoothService.disconnect();

        _showSuccessSnackBar('Connected to ${device.name}');
      } else {
        _showErrorSnackBar('Failed to connect to ${device.name}');
      }
    } catch (e) {
      _showErrorSnackBar('Error connecting to device: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testPrint() async {
    if (_connectedDeviceAddress == null) {
      _showErrorSnackBar('No printer connected');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _printerService.printTest();
      if (success) {
        _showSuccessSnackBar('Test print sent successfully');
      } else {
        _showErrorSnackBar('Failed to send test print');
      }
    } catch (e) {
      _showErrorSnackBar('Error during test print: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Bluetooth Printer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning || _isLoading ? null : _refreshDevicesList,
            tooltip: 'Refresh Devices',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Connected device info
          if (_connectedDeviceName != null)
            Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connected Printer',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _connectedDeviceName!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _testPrint,
                    child: const Text('Test Print'),
                  ),
                ],
              ),
            ),

          // Devices list
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select a Bluetooth Printer',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          _isScanning
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
            child: _devices.isEmpty
                ? const Center(
              child: Text('No paired devices found. Please pair your printer in Bluetooth settings.'),
            )
                : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                final isSelected = device.address == _selectedDeviceAddress;

                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  leading: Icon(
                    Icons.print,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.circle_outlined),
                  onTap: () => _connectToDevice(device),
                  selected: isSelected,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Done'),
        ),
      ),
    );
  }
}
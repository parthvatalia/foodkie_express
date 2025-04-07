
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../../utils/printer_services.dart';

class BluetoothPrinterSelectionScreen extends StatefulWidget {
  const BluetoothPrinterSelectionScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothPrinterSelectionScreen> createState() => _BluetoothPrinterSelectionScreenState();
}

class _BluetoothPrinterSelectionScreenState extends State<BluetoothPrinterSelectionScreen> {
  final PrinterService _printerService = PrinterService();
  bool _isLoading = true;
  bool _isBluetoothEnabled = false;
  List<BluetoothDevice> _devices = [];
  Map<String, String>? _currentPrinter;
  bool _isPrinterConnected = false;

  @override
  void initState() {
    super.initState();
    _loadBluetoothState();
  }

  Future<void> _loadBluetoothState() async {
    setState(() {
      _isLoading = true;
    });

    try {
      
      bool permissionsGranted = await _printerService.requestBluetoothPermissions();
      if (!permissionsGranted) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bluetooth permissions are required to use the printer'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      
      _isBluetoothEnabled = await _printerService.isBluetoothEnabled();

      
      if (_isBluetoothEnabled) {
        _currentPrinter = await _printerService.getSavedBluetoothPrinter();
        _devices = await _printerService.getAvailableBluetoothDevices();

        
        if (_currentPrinter != null) {
          _isPrinterConnected = await _printerService.isPrinterConnected();
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading Bluetooth state: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _enableBluetooth() async {
    try {
      bool enabled = await _printerService.requestEnableBluetooth();

      if (mounted) {
        if (enabled) {
          _loadBluetoothState(); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bluetooth must be enabled to use a printer')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error enabling Bluetooth: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectPrinter(BluetoothDevice device) async {
    setState(() {
      _isLoading = true;
    });

    try {
      
      await _printerService.saveBluetoothPrinter(
          device.address,
          device.name ?? 'Unknown Printer'
      );

      
      _isPrinterConnected = await _printerService.isPrinterConnected();

      if (_isPrinterConnected) {
        
        bool testSuccess = await _printerService.printTest();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  testSuccess
                      ? 'Printer connected and test successful!'
                      : 'Printer connected but test failed'
              ),
              backgroundColor: testSuccess ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not connect to printer. Please check if it is turned on.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      
      await _loadBluetoothState();
    } catch (e) {
      debugPrint('Error selecting printer: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Printer')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Printer')),
      body: !_isBluetoothEnabled
          ? _buildBluetoothDisabledView()
          : _buildDeviceList(),
    );
  }

  Widget _buildBluetoothDisabledView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_disabled, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Bluetooth is turned off',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Please enable Bluetooth to use a thermal printer'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _enableBluetooth,
            icon: const Icon(Icons.bluetooth),
            label: const Text('Enable Bluetooth'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.print, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No paired printers found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Please pair your thermal printer in Bluetooth settings'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _loadBluetoothState();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        if (_currentPrinter != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: _isPrinterConnected ? Colors.green[50] : Colors.orange[50],
            child: Row(
              children: [
                Icon(
                  _isPrinterConnected ? Icons.check_circle : Icons.error_outline,
                  color: _isPrinterConnected ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current printer: ${_currentPrinter?['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isPrinterConnected
                            ? 'Connected and ready'
                            : 'Not connected - please check if printer is turned on',
                        style: TextStyle(
                          color: _isPrinterConnected ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isPrinterConnected)
                  ElevatedButton(
                    onPressed: () async {
                      bool success = await _printerService.printTest();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                success ? 'Test print sent!' : 'Failed to print test page'
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Test'),
                  ),
              ],
            ),
          ),

        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Select a printer from the list below:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              final bool isSelected = _currentPrinter != null &&
                  _currentPrinter!['address'] == device.address;

              return ListTile(
                leading: Icon(
                  Icons.print,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                ),
                title: Text(
                  device.name ?? 'Unknown Device',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(device.address),
                trailing: isSelected
                    ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                )
                    : null,
                onTap: () => _selectPrinter(device),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Note: If your printer is not listed, please pair it in your device\'s Bluetooth settings first.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
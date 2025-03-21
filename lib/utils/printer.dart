import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService {
  // Get saved printer device
  Future<Printer?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final String? printer_name = prefs.getString('printer_name');

    if (printer_name == null) return null;

    // Get available printers
    final printers = await Printing.listPrinters();
    try {
      return printers.firstWhere((printer) => printer.name == printer_name);
    } catch (e) {
      return null;
    }
  }

  // Save printer device
  Future<void> savePrinter(Printer printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_name', printer.name);
  }

  Future<Uint8List?> _getImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return null;
    }
  }

  // Print receipt
  Future<bool> printReceipt(Map<String, dynamic> data) async {
    try {
      // Get receipt data
      final items = data['items'] as List<dynamic>;
      final total = data['total'] as double;
      final notes = data['notes'] as String?;
      final timestamp = data['timestamp'] as String;
      final orderNumber = data['orderNumber'] as String?;

      // Get restaurant info
      final restaurant = data['restaurant'] as Map<String, dynamic>?;
      final restaurantName =
          restaurant?['name'] as String? ?? 'FOODKIE EXPRESS';
      final restaurantAddress = restaurant?['address'] as String? ?? '';
      final restaurantEmail = restaurant?['email'] as String? ?? '';
      final logoUrl = restaurant?['logoUrl'] as String?;

      Uint8List? logoImage;
      if (logoUrl != null && logoUrl.isNotEmpty) {
        logoImage = await _getImageFromUrl(logoUrl);
      }
      // Create PDF document
      final pdf = pw.Document();

      // Add receipt page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoUrl != null && logoUrl.isNotEmpty)
                  if (logoImage != null)
                    pw.Container(
                      width: 60,
                      height: 60,
                      child: pw.Image(
                        pw.MemoryImage(logoImage),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                pw.SizedBox(height: 8),

                // Restaurant details
                pw.Text(
                  restaurantName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 8),

                // Restaurant address and email if available
                if (restaurantAddress.isNotEmpty)
                  pw.Text(
                    restaurantAddress,
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                if (restaurantEmail.isNotEmpty)
                  pw.Text(
                    "Email: $restaurantEmail",
                    style: const pw.TextStyle(fontSize: 9),
                  ),

                pw.SizedBox(height: 10),

                pw.Text(
                  'Receipt',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                // Order number if available
                if (orderNumber != null && orderNumber.isNotEmpty)
                  pw.Text(
                    "Order #$orderNumber",
                    style: const pw.TextStyle(fontSize: 10),
                  ),

                pw.Text(
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(DateTime.parse(timestamp)),
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Divider(),

                // Items
                ...items.map((item) {
                  final name = item['name'] as String;
                  final price = item['price'] as double;
                  final quantity = item['quantity'] as int;
                  final itemTotal = quantity * price;

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('$name($quantity)'),
                          pw.Text('Rs.${itemTotal.toStringAsFixed(2)}'),
                        ],
                      ),

                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'item Price',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            'Rs.${price.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 5),
                    ],
                  );
                }).toList(),

                pw.Divider(),

                // Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Rs.${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),

                // Notes
                if (notes != null && notes.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Text('Notes:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(notes, style: const pw.TextStyle(fontSize: 10)),
                ],

                // Footer
                pw.SizedBox(height: 20),
                pw.Text(
                  'Thank you for your order!',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Visit again', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 10),

                // "Made by Foodkie Express" on right side with small font
                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Text(
                    'Made by Foodkie Express',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Print the document
      final printer = await getSavedPrinter();
      if (printer != null) {
        // Print to specific printer
        return await Printing.directPrintPdf(
          printer: printer,
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
      } else {
        // Show print dialog
        return await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Foodkie Express Receipt',
          format: PdfPageFormat.roll80,
        );
      }
    } catch (e) {
      debugPrint('Printing error: $e');
      return false;
    }
  }

  // Test print
  Future<bool> printTest() async {
    try {
      // Create PDF document
      final pdf = pw.Document();

      // Add test page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Foodkie Express',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Test Print',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date'),
                    pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Time'),
                    pw.Text(DateFormat('HH:mm').format(DateTime.now())),
                  ],
                ),
                pw.Divider(),
                pw.Text('Printer test completed'),
              ],
            );
          },
        ),
      );

      // Print the document
      final printer = await getSavedPrinter();
      if (printer != null) {
        // Print to specific printer
        return await Printing.directPrintPdf(
          printer: printer,
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
      } else {
        // Show print dialog
        return await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Foodkie Express Test Print',
          format: PdfPageFormat.roll80,
        );
      }
    } catch (e) {
      debugPrint('Test print error: $e');
      return false;
    }
  }

  // Get available printers
  Future<List<Printer>> getAvailablePrinters() async {
    try {
      return await Printing.listPrinters();
    } catch (e) {
      debugPrint('Get printers error: $e');
      return [];
    }
  }
}

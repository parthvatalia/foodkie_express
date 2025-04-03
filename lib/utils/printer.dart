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

      // Calculate subtotal (assumes total might include tax)
      final subtotal = items.fold<double>(
        0,
        (sum, item) =>
            sum + (item['price'] as double) * (item['quantity'] as int),
      );

      // Calculate tax (if any)
      final tax = total - subtotal;

      Uint8List? logoImage;
      if (logoUrl != null && logoUrl.isNotEmpty) {
        logoImage = await _getImageFromUrl(logoUrl);
      }

      // Create PDF document with monospaced font for that receipt look
      final pdf = pw.Document();

      // Define font for the receipt (monospaced for that classic receipt look)
      final font = pw.Font.courier();

      // Add receipt page
      pdf.addPage(
        pw.Page(
          theme: pw.ThemeData.withFont(
            base: font,
            bold: font,
            italic: font,
            boldItalic: font,
          ),
          build: (pw.Context context) {
            return pw.Container(
              child: pw.Center(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,

                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          // Logo if available
                          if (logoImage != null)
                            pw.Container(
                              width: 100,
                              height: 50,
                              alignment: pw.Alignment.center,
                              child: pw.Image(
                                pw.MemoryImage(logoImage),
                                fit: pw.BoxFit.contain,
                              ),
                            ),

                          // Restaurant name and address in UPPERCASE
                          pw.Center(
                            child: pw.Text(
                              restaurantName.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),

                          if (restaurantAddress.isNotEmpty)
                            pw.Center(
                              child: pw.Text(
                                restaurantAddress.toUpperCase(),
                                style: pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),

                          if (restaurantEmail.isNotEmpty)
                            pw.Center(
                              child: pw.Text(
                                restaurantEmail.toUpperCase(),
                                style: pw.TextStyle(fontSize: 7),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),

                          pw.SizedBox(height: 10),

                          // Order and host info
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "ORDER : ${orderNumber ?? '---'}",
                                style: pw.TextStyle(fontSize: 9),
                              ),
                              pw.Text(
                                DateFormat(
                                  'MM/dd/yyyy',
                                ).format(DateTime.parse(timestamp)),
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ],
                          ),

                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                DateFormat(
                                  'hh:mm a',
                                ).format(DateTime.parse(timestamp)),
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ],
                          ),

                          pw.SizedBox(height: 10),

                          // Items with clear spacing
                          ...items.map((item) {
                            final name = item['name'] as String;
                            final price = item['price'] as double;
                            final quantity = item['quantity'] as int;
                            final itemTotal = quantity * price;

                            return pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.SizedBox(
                                  width: 15,
                                  child: pw.Text(
                                    "$quantity",
                                    style: pw.TextStyle(fontSize: 9),
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Text(
                                    name.toUpperCase(),
                                    style: pw.TextStyle(fontSize: 9),
                                  ),
                                ),
                                pw.SizedBox(
                                  width: 60,
                                  child: pw.Text(
                                    "rs.${itemTotal.toStringAsFixed(2)}",
                                    style: pw.TextStyle(fontSize: 9),
                                    textAlign: pw.TextAlign.right,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),

                          pw.SizedBox(height: 10),

                          // Totals section
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "SUBTOTAL",
                                style: pw.TextStyle(fontSize: 9),
                              ),
                              pw.Text(
                                "rs.${subtotal.toStringAsFixed(2)}",
                                style: pw.TextStyle(fontSize: 9),
                                textAlign: pw.TextAlign.right,
                              ),
                            ],
                          ),

                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "TOTAL:",
                                style: pw.TextStyle(fontSize: 9),
                              ),
                              pw.Text(
                                "rs.${total.toStringAsFixed(2)}",
                                style: pw.TextStyle(fontSize: 9),
                                textAlign: pw.TextAlign.right,
                              ),
                            ],
                          ),

                          pw.SizedBox(height: 10),

                          // Signature line
                          pw.Text(
                            "..............................",
                            style: pw.TextStyle(fontSize: 9),
                          ),

                          pw.SizedBox(height: 20),

                          // Footer
                          pw.Center(
                            child: pw.Text(
                              "CUSTOMER COPY",
                              style: pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),

                          pw.Center(
                            child: pw.Text(
                              "Thank you for your order!",
                              style: pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),

                          pw.Center(
                            child: pw.Text(
                              "Visit again",
                              style: pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.SizedBox(height: 20),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                "Made by Foodkie Express",
                                style: pw.TextStyle(fontSize: 7),
                                textAlign: pw.TextAlign.center,
                              ),
                            ],
                          ),

                          // Notes section if there are any
                          if (notes != null && notes.isNotEmpty) ...[
                            pw.SizedBox(height: 10),
                            pw.Text(
                              "NOTES: $notes",
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

      // Define font for the receipt
      final font = pw.Font.courier();

      // Add test page
      pdf.addPage(
        pw.Page(
          theme: pw.ThemeData.withFont(
            base: font,
            bold: font,
            italic: font,
            boldItalic: font,
          ),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Center(
                  child: pw.Text(
                    'FOODKIE EXPRESS',
                    style: pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                pw.Center(
                  child: pw.Text(
                    '123 FOOD STREET, CITY',
                    style: pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                pw.SizedBox(height: 10),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("ORDER : TEST", style: pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      DateFormat('MM/dd/yyyy').format(DateTime.now()),
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("HOST : TEST", style: pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      DateFormat('hh:mm a').format(DateTime.now()),
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 15,
                      child: pw.Text("1", style: pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        "TEST ITEM",
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.SizedBox(
                      width: 60,
                      child: pw.Text(
                        "₹ 10.00",
                        style: pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 15),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("TOTAL:", style: pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      "₹ 10.00",
                      style: pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.right,
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                pw.Center(
                  child: pw.Text(
                    "PRINTER TEST COMPLETED",
                    style: pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
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
          name: 'Foodkie Express Test Print',
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

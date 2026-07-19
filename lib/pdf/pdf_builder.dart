import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice.dart';
import '../utils/formatters.dart';

class PdfBuilder {
  static Future<Uint8List> buildPdf({
    required Invoice invoice,
    required String currencySymbol,
    String template = 'Classic',
  }) async {
    final pdf = pw.Document();

    // Load company logo if path exists
    pw.MemoryImage? logoImage;
    if (!kIsWeb &&
        invoice.businessInfo.logoPath != null &&
        invoice.businessInfo.logoPath!.isNotEmpty &&
        File(invoice.businessInfo.logoPath!).existsSync()) {
      final logoBytes = await File(invoice.businessInfo.logoPath!).readAsBytes();
      logoImage = pw.MemoryImage(logoBytes);
    }

    // Determine template colors
    PdfColor primaryColor;
    PdfColor headerBg;
    if (template == 'Modern') {
      primaryColor = PdfColors.indigo700;
      headerBg = PdfColors.indigo50;
    } else if (template == 'Minimal') {
      primaryColor = PdfColors.grey900;
      headerBg = PdfColors.grey100;
    } else {
      // Classic
      primaryColor = PdfColors.blue800;
      headerBg = PdfColors.blue50;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: headerBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 80,
                          height: 40,
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                      pw.Text(
                        invoice.businessInfo.name.isNotEmpty
                            ? invoice.businessInfo.name
                            : 'Company Name',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      if (invoice.businessInfo.address.isNotEmpty)
                        pw.Text(invoice.businessInfo.address, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      if (invoice.businessInfo.email.isNotEmpty)
                        pw.Text(invoice.businessInfo.email, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      if (invoice.businessInfo.phone.isNotEmpty)
                        pw.Text(invoice.businessInfo.phone, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      if (invoice.businessInfo.taxId.isNotEmpty)
                        pw.Text('Tax ID: ${invoice.businessInfo.taxId}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('#${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      pw.Text('Date: ${Formatters.dateShort(invoice.invoiceDate)}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Due Date: ${Formatters.dateShort(invoice.dueDate)}', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: invoice.effectiveStatus == 'Paid'
                              ? PdfColors.green100
                              : (invoice.effectiveStatus == 'Overdue' ? PdfColors.red100 : PdfColors.orange100),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          invoice.effectiveStatus.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: invoice.effectiveStatus == 'Paid'
                                ? PdfColors.green800
                                : (invoice.effectiveStatus == 'Overdue' ? PdfColors.red800 : PdfColors.orange800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Customer Info Box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILLED TO:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.customerInfo.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  if (invoice.customerInfo.address.isNotEmpty)
                    pw.Text(invoice.customerInfo.address, style: const pw.TextStyle(fontSize: 10)),
                  if (invoice.customerInfo.email.isNotEmpty)
                    pw.Text('Email: ${invoice.customerInfo.email}', style: const pw.TextStyle(fontSize: 10)),
                  if (invoice.customerInfo.phone.isNotEmpty)
                    pw.Text('Phone: ${invoice.customerInfo.phone}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Line Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryColor),
                  children: [
                    _tableHeaderCell('Item / Service', alignLeft: true),
                    _tableHeaderCell('Qty'),
                    _tableHeaderCell('Unit Price'),
                    _tableHeaderCell('Disc %'),
                    _tableHeaderCell('Total', alignRight: true),
                  ],
                ),
                // Table Rows
                ...invoice.items.map((item) {
                  return pw.TableRow(
                    children: [
                      _tableBodyCell(item.name, alignLeft: true),
                      _tableBodyCell(item.quantity.toString()),
                      _tableBodyCell(Formatters.currency(item.unitPrice, symbol: currencySymbol)),
                      _tableBodyCell('${item.discountPercent.toStringAsFixed(0)}%'),
                      _tableBodyCell(Formatters.currency(item.itemTotal, symbol: currencySymbol), alignRight: true),
                    ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 16),

            // Calculation Summary Box
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal:', Formatters.currency(invoice.subtotal, symbol: currencySymbol)),
                      if (invoice.totalDiscount > 0)
                        _summaryRow('Total Discount:', '-${Formatters.currency(invoice.totalDiscount, symbol: currencySymbol)}', isDiscount: true),
                      _summaryRow('Tax (${invoice.taxRate.toStringAsFixed(1)}%):', Formatters.currency(invoice.taxAmount, symbol: currencySymbol)),
                      pw.Divider(color: PdfColors.grey400),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            pw.Text(
                              Formatters.currency(invoice.grandTotal, symbol: currencySymbol),
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // Notes & Payment Instructions
            if (invoice.notes.isNotEmpty || (invoice.businessInfo.paymentDetails != null && invoice.businessInfo.paymentDetails!.isNotEmpty))
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (invoice.notes.isNotEmpty) ...[
                          pw.Text('Notes & Instructions:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          pw.SizedBox(height: 2),
                          pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          pw.SizedBox(height: 10),
                        ],
                        if (invoice.businessInfo.paymentDetails != null && invoice.businessInfo.paymentDetails!.isNotEmpty) ...[
                          pw.Text('Payment Details:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          pw.SizedBox(height: 2),
                          pw.Text(invoice.businessInfo.paymentDetails!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Render QR Code widget
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'Invoice:${invoice.invoiceNumber}\nAmount:${invoice.grandTotal.toStringAsFixed(2)}\nPayee:${invoice.businessInfo.name}',
                    width: 70,
                    height: 70,
                  ),
                ],
              ),

            pw.Spacer(),

            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _tableHeaderCell(String text, {bool alignLeft = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : (alignLeft ? pw.TextAlign.left : pw.TextAlign.center),
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _tableBodyCell(String text, {bool alignLeft = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : (alignLeft ? pw.TextAlign.left : pw.TextAlign.center),
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isDiscount = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: isDiscount ? PdfColors.green700 : PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }
}

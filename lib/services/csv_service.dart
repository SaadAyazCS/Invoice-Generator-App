import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/invoice.dart';
import '../utils/formatters.dart';

class CsvService {
  static Future<String> exportInvoicesToCsv(List<Invoice> invoices, String currencySymbol) async {
    List<List<dynamic>> rows = [
      [
        'Invoice Number',
        'Invoice Date',
        'Due Date',
        'Customer Name',
        'Customer Email',
        'Status',
        'Subtotal',
        'Tax Rate (%)',
        'Tax Amount',
        'Grand Total',
      ]
    ];

    for (var inv in invoices) {
      rows.add([
        inv.invoiceNumber,
        Formatters.dateShort(inv.invoiceDate),
        Formatters.dateShort(inv.dueDate),
        inv.customerInfo.name,
        inv.customerInfo.email,
        inv.effectiveStatus,
        inv.subtotal.toStringAsFixed(2),
        inv.taxRate.toStringAsFixed(2),
        inv.taxAmount.toStringAsFixed(2),
        inv.grandTotal.toStringAsFixed(2),
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/invoices_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);
    return file.path;
  }
}

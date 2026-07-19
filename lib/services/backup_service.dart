import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';

class BackupService {
  static Future<String> exportBackup() async {
    final dbService = DatabaseService();
    final invoices = await dbService.getAllInvoices();
    final customers = await dbService.getAllCustomers();
    final products = await dbService.getAllProducts();
    final company = await dbService.getCompanyProfile();
    final settings = await dbService.getAppSettings();

    final backupData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'company': company.toMap(),
      'settings': settings.toMap(),
      'customers': customers.map((c) => c.toMap()).toList(),
      'products': products.map((p) => p.toMap()).toList(),
      'invoices': invoices.map((inv) => inv.toMap()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/invoice_master_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);
    return file.path;
  }
}

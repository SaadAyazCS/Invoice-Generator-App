import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/app_settings.dart';
import '../models/company_profile.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // --- INVOICES CRUD ---

  Future<List<Invoice>> getAllInvoices() async {
    final db = await DBHelper.database;
    final List<Map<String, dynamic>> invoiceMaps = await db.query('invoices', orderBy: 'createdAt DESC');

    List<Invoice> invoices = [];
    for (var map in invoiceMaps) {
      final String invoiceId = map['id'];
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'invoice_items',
        where: 'invoiceId = ?',
        whereArgs: [invoiceId],
      );
      final items = itemMaps.map((e) => InvoiceItem.fromMap(e)).toList();
      invoices.add(Invoice.fromMap(map, items));
    }
    return invoices;
  }

  Future<Invoice?> getInvoiceById(String id) async {
    final db = await DBHelper.database;
    final List<Map<String, dynamic>> invoiceMaps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (invoiceMaps.isEmpty) return null;

    final List<Map<String, dynamic>> itemMaps = await db.query(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [id],
    );
    final items = itemMaps.map((e) => InvoiceItem.fromMap(e)).toList();
    return Invoice.fromMap(invoiceMaps.first, items);
  }

  Future<void> insertInvoice(Invoice invoice) async {
    final db = await DBHelper.database;
    await db.transaction((txn) async {
      await txn.insert('invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (var item in invoice.items) {
        await txn.insert('invoice_items', item.toMap(invoice.id), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateInvoice(Invoice invoice) async {
    final db = await DBHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'invoices',
        invoice.toMap(),
        where: 'id = ?',
        whereArgs: [invoice.id],
      );
      // Remove old items and re-insert
      await txn.delete('invoice_items', where: 'invoiceId = ?', whereArgs: [invoice.id]);
      for (var item in invoice.items) {
        await txn.insert('invoice_items', item.toMap(invoice.id));
      }
    });
  }

  Future<void> updateInvoiceStatus(String invoiceId, String newStatus) async {
    final db = await DBHelper.database;
    await db.update(
      'invoices',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final db = await DBHelper.database;
    await db.transaction((txn) async {
      await txn.delete('invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]);
      await txn.delete('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    });
  }

  // --- COMPANY PROFILE CRUD ---

  Future<CompanyProfile> getCompanyProfile() async {
    final db = await DBHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('company_profile', where: 'id = 1');
    if (maps.isNotEmpty) {
      return CompanyProfile.fromMap(maps.first);
    }
    return CompanyProfile();
  }

  Future<void> updateCompanyProfile(CompanyProfile profile) async {
    final db = await DBHelper.database;
    final map = profile.toMap();
    map['id'] = 1;
    await db.insert('company_profile', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- APP SETTINGS CRUD ---

  Future<AppSettings> getAppSettings() async {
    final db = await DBHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('app_settings', where: 'id = 1');
    if (maps.isNotEmpty) {
      return AppSettings.fromMap(maps.first);
    }
    return AppSettings();
  }

  Future<void> updateAppSettings(AppSettings settings) async {
    final db = await DBHelper.database;
    final map = settings.toMap();
    map['id'] = 1;
    await db.insert('app_settings', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> generateNextInvoiceNumber() async {
    final settings = await getAppSettings();
    final nextNum = settings.nextInvoiceNumber;
    final formattedNumber = '${settings.invoicePrefix}${nextNum.toString().padLeft(3, '0')}';
    
    // Increment next number in settings
    await updateAppSettings(settings.copyWith(nextInvoiceNumber: nextNum + 1));
    return formattedNumber;
  }

  // --- CUSTOMERS CRUD ---

  Future<List<Customer>> getAllCustomers() async {
    final db = await DBHelper.database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map((e) => Customer.fromMap(e)).toList();
  }

  Future<void> insertCustomer(Customer customer) async {
    final db = await DBHelper.database;
    await db.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await DBHelper.database;
    await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<void> deleteCustomer(String id) async {
    final db = await DBHelper.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // --- PRODUCTS CRUD ---

  Future<List<Product>> getAllProducts() async {
    final db = await DBHelper.database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((e) => Product.fromMap(e)).toList();
  }

  Future<void> insertProduct(Product product) async {
    final db = await DBHelper.database;
    await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProduct(Product product) async {
    final db = await DBHelper.database;
    await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> deleteProduct(String id) async {
    final db = await DBHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}

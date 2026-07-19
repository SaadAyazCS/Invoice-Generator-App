import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final docsDir = await getApplicationDocumentsDirectory();
      path = join(docsDir.path, 'invoice_master_pro.db');
    } else {
      path = join(await getDatabasesPath(), 'invoice_master_pro.db');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE company_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL,
        address TEXT,
        email TEXT,
        phone TEXT,
        taxId TEXT,
        logoPath TEXT,
        paymentDetails TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        currency TEXT,
        defaultTaxRate REAL,
        invoicePrefix TEXT,
        nextInvoiceNumber INTEGER,
        isDarkMode INTEGER,
        pdfTemplate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        email TEXT,
        phone TEXT,
        isFavorite INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        unitPrice REAL NOT NULL,
        unit TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        invoiceNumber TEXT NOT NULL,
        invoiceDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        businessName TEXT,
        businessAddress TEXT,
        businessEmail TEXT,
        businessPhone TEXT,
        businessTaxId TEXT,
        businessLogoPath TEXT,
        businessPaymentDetails TEXT,
        customerName TEXT NOT NULL,
        customerAddress TEXT,
        customerEmail TEXT,
        customerPhone TEXT,
        taxRate REAL,
        notes TEXT,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id TEXT PRIMARY KEY,
        invoiceId TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        discountPercent REAL DEFAULT 0.0,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // Seed initial company profile & app settings
    await db.insert('company_profile', {
      'id': 1,
      'name': 'Acme Solutions Ltd',
      'address': '123 Business Way, Suite 400',
      'email': 'billing@acmesolutions.com',
      'phone': '+1 (555) 019-2834',
      'taxId': 'TAX-998822',
      'logoPath': null,
      'paymentDetails': 'Bank: Chase Bank | Account: 1234-5678-9012\nSWIFT: ACMEUS33 | UPI/PayPal: pay@acme.com',
    });

    await db.insert('app_settings', {
      'id': 1,
      'currency': '\$',
      'defaultTaxRate': 10.0,
      'invoicePrefix': 'INV-',
      'nextInvoiceNumber': 1,
      'isDarkMode': 0,
      'pdfTemplate': 'Classic',
    });

    // Seed sample catalog items & sample customer
    await db.insert('customers', {
      'id': 'cust-1',
      'name': 'Apex Global Tech',
      'address': '789 Innovation Ave, New York, NY',
      'email': 'contact@apexglobal.com',
      'phone': '+1 (212) 555-0199',
      'isFavorite': 1,
    });

    await db.insert('products', {
      'id': 'prod-1',
      'name': 'Web Development Service',
      'unitPrice': 1500.0,
      'unit': 'project',
      'description': 'Full stack web application design & development',
    });

    await db.insert('products', {
      'id': 'prod-2',
      'name': 'UI/UX Mobile Design',
      'unitPrice': 850.0,
      'unit': 'project',
      'description': 'Mobile responsive UI design screens',
    });
  }
}

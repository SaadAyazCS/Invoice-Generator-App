import 'package:uuid/uuid.dart';
import 'company_profile.dart';
import 'customer.dart';
import 'invoice_item.dart';

class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final CompanyProfile businessInfo;
  final Customer customerInfo;
  final List<InvoiceItem> items;
  final double taxRate;
  final String notes;
  final String status; // 'Paid', 'Unpaid', 'Overdue'
  final DateTime createdAt;

  Invoice({
    String? id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.businessInfo,
    required this.customerInfo,
    required this.items,
    this.taxRate = 10.0,
    this.notes = '',
    this.status = 'Unpaid',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.itemTotal);
  double get totalDiscount => items.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get taxAmount => subtotal * (taxRate / 100.0);
  double get grandTotal => subtotal + taxAmount;

  bool get isOverdue {
    if (status == 'Paid') return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  String get effectiveStatus => isOverdue ? 'Overdue' : status;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'businessName': businessInfo.name,
      'businessAddress': businessInfo.address,
      'businessEmail': businessInfo.email,
      'businessPhone': businessInfo.phone,
      'businessTaxId': businessInfo.taxId,
      'businessLogoPath': businessInfo.logoPath,
      'businessPaymentDetails': businessInfo.paymentDetails,
      'customerName': customerInfo.name,
      'customerAddress': customerInfo.address,
      'customerEmail': customerInfo.email,
      'customerPhone': customerInfo.phone,
      'taxRate': taxRate,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, List<InvoiceItem> items) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoiceNumber'],
      invoiceDate: DateTime.parse(map['invoiceDate']),
      dueDate: DateTime.parse(map['dueDate']),
      businessInfo: CompanyProfile(
        name: map['businessName'] ?? '',
        address: map['businessAddress'] ?? '',
        email: map['businessEmail'] ?? '',
        phone: map['businessPhone'] ?? '',
        taxId: map['businessTaxId'] ?? '',
        logoPath: map['businessLogoPath'],
        paymentDetails: map['businessPaymentDetails'] ?? '',
      ),
      customerInfo: Customer(
        name: map['customerName'] ?? '',
        address: map['customerAddress'] ?? '',
        email: map['customerEmail'] ?? '',
        phone: map['customerPhone'] ?? '',
      ),
      items: items,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 10.0,
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'Unpaid',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  Invoice copyWith({
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    CompanyProfile? businessInfo,
    Customer? customerInfo,
    List<InvoiceItem>? items,
    double? taxRate,
    String? notes,
    String? status,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      businessInfo: businessInfo ?? this.businessInfo,
      customerInfo: customerInfo ?? this.customerInfo,
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

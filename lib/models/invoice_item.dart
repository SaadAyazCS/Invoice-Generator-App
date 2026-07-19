import 'package:uuid/uuid.dart';

class InvoiceItem {
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final double discountPercent;

  InvoiceItem({
    String? id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0.0,
  }) : id = id ?? const Uuid().v4();

  double get rawTotal => quantity * unitPrice;
  double get discountAmount => rawTotal * (discountPercent / 100.0);
  double get itemTotal => rawTotal - discountAmount;

  Map<String, dynamic> toMap(String invoiceId) {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercent': discountPercent,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      unitPrice: (map['unitPrice'] as num).toDouble(),
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  InvoiceItem copyWith({
    String? name,
    int? quantity,
    double? unitPrice,
    double? discountPercent,
  }) {
    return InvoiceItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }
}

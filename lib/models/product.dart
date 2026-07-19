import 'package:uuid/uuid.dart';

class Product {
  final String id;
  final String name;
  final double unitPrice;
  final String unit;
  final String description;

  Product({
    String? id,
    required this.name,
    required this.unitPrice,
    this.unit = 'pcs',
    this.description = '',
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unitPrice': unitPrice,
      'unit': unit,
      'description': description,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      unitPrice: (map['unitPrice'] as num).toDouble(),
      unit: map['unit'] ?? 'pcs',
      description: map['description'] ?? '',
    );
  }

  Product copyWith({
    String? name,
    double? unitPrice,
    String? unit,
    String? description,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
      description: description ?? this.description,
    );
  }
}

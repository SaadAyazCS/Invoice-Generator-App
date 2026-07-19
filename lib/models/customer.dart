import 'package:uuid/uuid.dart';

class Customer {
  final String id;
  final String name;
  final String address;
  final String email;
  final String phone;
  final bool isFavorite;

  Customer({
    String? id,
    required this.name,
    this.address = '',
    this.email = '',
    this.phone = '',
    this.isFavorite = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'email': email,
      'phone': phone,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      isFavorite: (map['isFavorite'] ?? 0) == 1,
    );
  }

  Customer copyWith({
    String? name,
    String? address,
    String? email,
    String? phone,
    bool? isFavorite,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class CompanyProfile {
  final String name;
  final String address;
  final String email;
  final String phone;
  final String taxId;
  final String? logoPath;
  final String? paymentDetails;

  CompanyProfile({
    this.name = 'My Business',
    this.address = '123 Main Street, Suite 100',
    this.email = 'contact@business.com',
    this.phone = '+1 (555) 012-3456',
    this.taxId = 'TAX-12345',
    this.logoPath,
    this.paymentDetails = 'Bank: Chase Bank | Account: 1234-5678-9012\nSWIFT: BUSI123 | UPI/PayPal: pay@business.com',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'email': email,
      'phone': phone,
      'taxId': taxId,
      'logoPath': logoPath,
      'paymentDetails': paymentDetails,
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      taxId: map['taxId'] ?? '',
      logoPath: map['logoPath'],
      paymentDetails: map['paymentDetails'] ?? '',
    );
  }

  CompanyProfile copyWith({
    String? name,
    String? address,
    String? email,
    String? phone,
    String? taxId,
    String? logoPath,
    String? paymentDetails,
  }) {
    return CompanyProfile(
      name: name ?? this.name,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      taxId: taxId ?? this.taxId,
      logoPath: logoPath ?? this.logoPath,
      paymentDetails: paymentDetails ?? this.paymentDetails,
    );
  }
}

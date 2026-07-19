class CompanyProfile {
  final String name;
  final String address;
  final String email;
  final String phone;
  final String taxId;
  final String? logoPath;
  final String? paymentDetails;

  CompanyProfile({
    this.name = 'Acme Solutions Ltd',
    this.address = '123 Business Way, Suite 400',
    this.email = 'billing@acmesolutions.com',
    this.phone = '+1 (555) 019-2834',
    this.taxId = 'TAX-998822',
    this.logoPath,
    this.paymentDetails = 'Bank Transfer: Account #1234-5678-9012\nSWIFT: ACMEUS33\nUPI / PayPal: pay@acme.com',
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

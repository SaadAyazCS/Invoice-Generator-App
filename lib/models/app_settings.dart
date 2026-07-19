class AppSettings {
  final String currency;
  final double defaultTaxRate;
  final String invoicePrefix;
  final int nextInvoiceNumber;
  final bool isDarkMode;
  final String pdfTemplate; // 'Classic', 'Modern', 'Minimal'

  AppSettings({
    this.currency = '\$',
    this.defaultTaxRate = 10.0,
    this.invoicePrefix = 'INV-',
    this.nextInvoiceNumber = 1,
    this.isDarkMode = false,
    this.pdfTemplate = 'Classic',
  });

  Map<String, dynamic> toMap() {
    return {
      'currency': currency,
      'defaultTaxRate': defaultTaxRate,
      'invoicePrefix': invoicePrefix,
      'nextInvoiceNumber': nextInvoiceNumber,
      'isDarkMode': isDarkMode ? 1 : 0,
      'pdfTemplate': pdfTemplate,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      currency: map['currency'] ?? '\$',
      defaultTaxRate: (map['defaultTaxRate'] as num?)?.toDouble() ?? 10.0,
      invoicePrefix: map['invoicePrefix'] ?? 'INV-',
      nextInvoiceNumber: map['nextInvoiceNumber'] ?? 1,
      isDarkMode: (map['isDarkMode'] ?? 0) == 1,
      pdfTemplate: map['pdfTemplate'] ?? 'Classic',
    );
  }

  AppSettings copyWith({
    String? currency,
    double? defaultTaxRate,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    bool? isDarkMode,
    String? pdfTemplate,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      pdfTemplate: pdfTemplate ?? this.pdfTemplate,
    );
  }
}

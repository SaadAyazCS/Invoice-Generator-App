import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_generator_app/models/company_profile.dart';
import 'package:invoice_generator_app/models/customer.dart';
import 'package:invoice_generator_app/models/invoice.dart';
import 'package:invoice_generator_app/models/invoice_item.dart';

void main() {
  test('Invoice calculation tests', () {
    final item1 = InvoiceItem(name: 'Web Dev', quantity: 2, unitPrice: 100.0, discountPercent: 10.0);
    final item2 = InvoiceItem(name: 'Hosting', quantity: 1, unitPrice: 50.0);

    expect(item1.rawTotal, 200.0);
    expect(item1.discountAmount, 20.0);
    expect(item1.itemTotal, 180.0);

    final invoice = Invoice(
      invoiceNumber: 'INV-001',
      invoiceDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 7)),
      businessInfo: CompanyProfile(name: 'Test Corp'),
      customerInfo: Customer(name: 'Client A'),
      items: [item1, item2],
      taxRate: 10.0,
    );

    expect(invoice.subtotal, 230.0); // 180 + 50
    expect(invoice.taxAmount, 23.0); // 10% of 230
    expect(invoice.grandTotal, 253.0);
  });
}

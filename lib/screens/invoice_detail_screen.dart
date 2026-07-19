import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/invoice.dart';
import '../pdf/pdf_builder.dart';
import '../services/database_service.dart';
import '../services/share_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';
import 'create_edit_invoice_screen.dart';
import 'pdf_preview_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _dbService = DatabaseService();
  Invoice? _invoice;
  String _currencySymbol = '\$';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() => _isLoading = true);
    final settings = await _dbService.getAppSettings();
    final inv = await _dbService.getInvoiceById(widget.invoiceId);
    setState(() {
      _currencySymbol = settings.currency;
      _invoice = inv;
      _isLoading = false;
    });
  }

  Future<void> _sharePdf() async {
    if (_invoice == null) return;
    final settings = await _dbService.getAppSettings();
    final pdfBytes = await PdfBuilder.buildPdf(
      invoice: _invoice!,
      currencySymbol: _currencySymbol,
      template: settings.pdfTemplate,
    );
    await ShareService.shareBytes(
      pdfBytes,
      'Invoice_${_invoice!.invoiceNumber}.pdf',
      text: 'Here is your invoice #${_invoice!.invoiceNumber} for ${Formatters.currency(_invoice!.grandTotal, symbol: _currencySymbol)}',
      subject: 'Invoice #${_invoice!.invoiceNumber}',
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Invoice?'),
          content: Text('Are you sure you want to delete invoice ${_invoice!.invoiceNumber}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.overdueColor),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _dbService.deleteInvoice(_invoice!.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Not Found')),
        body: const Center(child: Text('Invoice does not exist or was deleted.')),
      );
    }

    final inv = _invoice!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${inv.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PdfPreviewScreen(invoice: inv)),
              );
            },
            tooltip: 'View & Print PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _sharePdf,
            tooltip: 'Share Invoice PDF',
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              switch (val) {
                case 'edit':
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateEditInvoiceScreen(invoiceToEdit: inv),
                    ),
                  );
                  if (updated == true) _loadInvoice();
                  break;
                case 'duplicate':
                  final dup = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateEditInvoiceScreen(
                        invoiceToEdit: inv,
                        isDuplicating: true,
                      ),
                    ),
                  );
                  if (dup == true && mounted) Navigator.pop(context, true);
                  break;
                case 'delete':
                  _confirmDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit Invoice')],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [Icon(Icons.copy_rounded, size: 18), SizedBox(width: 8), Text('Duplicate Invoice')],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [Icon(Icons.delete_outline_rounded, color: AppTheme.overdueColor, size: 18), SizedBox(width: 8), Text('Delete Invoice', style: TextStyle(color: AppTheme.overdueColor))],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.invoiceNumber,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text('Issued: ${Formatters.date(inv.invoiceDate)} | Due: ${Formatters.date(inv.dueDate)}'),
                    ],
                  ),
                  StatusBadge(status: inv.effectiveStatus, isLarge: true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Status Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: inv.effectiveStatus == 'Paid'
                        ? OutlinedButton.styleFrom(backgroundColor: AppTheme.paidColor.withOpacity(0.1))
                        : null,
                    onPressed: () async {
                      await _dbService.updateInvoiceStatus(inv.id, 'Paid');
                      _loadInvoice();
                    },
                    icon: const Icon(Icons.check_circle_outline, color: AppTheme.paidColor),
                    label: const Text('Mark Paid'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: inv.effectiveStatus == 'Unpaid'
                        ? OutlinedButton.styleFrom(backgroundColor: AppTheme.unpaidColor.withOpacity(0.1))
                        : null,
                    onPressed: () async {
                      await _dbService.updateInvoiceStatus(inv.id, 'Unpaid');
                      _loadInvoice();
                    },
                    icon: const Icon(Icons.hourglass_top_rounded, color: AppTheme.unpaidColor),
                    label: const Text('Mark Unpaid'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Customer Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CUSTOMER INFO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  const SizedBox(height: 8),
                  Text(inv.customerInfo.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (inv.customerInfo.address.isNotEmpty) Text(inv.customerInfo.address, style: const TextStyle(fontSize: 13)),
                  if (inv.customerInfo.email.isNotEmpty) Text(inv.customerInfo.email, style: const TextStyle(fontSize: 13)),
                  if (inv.customerInfo.phone.isNotEmpty) Text(inv.customerInfo.phone, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Items Table
            const Text('LINE ITEMS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            ...inv.items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${item.quantity} x ${Formatters.currency(item.unitPrice, symbol: _currencySymbol)}'
                            '${item.discountPercent > 0 ? " (Disc: ${item.discountPercent.toStringAsFixed(0)}%)" : ""}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.currency(item.itemTotal, symbol: _currencySymbol),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            // Grand Total Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text(Formatters.currency(inv.subtotal, symbol: _currencySymbol), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (inv.totalDiscount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Discount:'),
                        Text('-${Formatters.currency(inv.totalDiscount, symbol: _currencySymbol)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.paidColor)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tax (${inv.taxRate.toStringAsFixed(1)}%):'),
                      Text(Formatters.currency(inv.taxAmount, symbol: _currencySymbol), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      Text(Formatters.currency(inv.grandTotal, symbol: _currencySymbol), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // QR Code for Payment & Notes
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (inv.notes.isNotEmpty) ...[
                        const Text('NOTES:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        const SizedBox(height: 4),
                        Text(inv.notes, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 12),
                      ],
                      if (inv.businessInfo.paymentDetails != null && inv.businessInfo.paymentDetails!.isNotEmpty) ...[
                        const Text('PAYMENT DETAILS:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        const SizedBox(height: 4),
                        Text(inv.businessInfo.paymentDetails!, style: const TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: 'Invoice:${inv.invoiceNumber}\nAmount:${inv.grandTotal.toStringAsFixed(2)}',
                    version: QrVersions.auto,
                    size: 80.0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PdfPreviewScreen(invoice: inv)),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Preview & Download PDF'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../pdf/pdf_builder.dart';
import '../services/csv_service.dart';
import '../services/database_service.dart';
import '../services/share_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/invoice_tile.dart';
import 'create_edit_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  final String? initialFilter;

  const InvoiceListScreen({super.key, this.initialFilter});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> with SingleTickerProviderStateMixin {
  final _dbService = DatabaseService();
  late TabController _tabController;

  List<Invoice> _allInvoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _currencySymbol = '\$';

  final List<String> _tabs = ['All', 'Paid', 'Unpaid', 'Overdue'];

  @override
  void initState() {
    super.initState();
    int initialIdx = 0;
    if (widget.initialFilter != null) {
      final idx = _tabs.indexOf(widget.initialFilter!);
      if (idx != -1) initialIdx = idx;
    }

    _tabController = TabController(length: _tabs.length, initialIndex: initialIdx, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _applyFilters();
      }
    });

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final settings = await _dbService.getAppSettings();
    final list = await _dbService.getAllInvoices();

    setState(() {
      _currencySymbol = settings.currency;
      _allInvoices = list;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final currentTab = _tabs[_tabController.index];
    List<Invoice> list = List.from(_allInvoices);

    if (currentTab == 'Paid') {
      list = list.where((i) => i.effectiveStatus == 'Paid').toList();
    } else if (currentTab == 'Unpaid') {
      list = list.where((i) => i.effectiveStatus == 'Unpaid').toList();
    } else if (currentTab == 'Overdue') {
      list = list.where((i) => i.effectiveStatus == 'Overdue').toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((i) {
        return i.invoiceNumber.toLowerCase().contains(query) ||
            i.customerInfo.name.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredInvoices = list;
    });
  }

  Future<void> _confirmDelete(Invoice invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Invoice?'),
          content: Text('Are you sure you want to delete invoice ${invoice.invoiceNumber}?'),
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
      await _dbService.deleteInvoice(invoice.id);
      _loadData();
    }
  }

  Future<void> _exportCsv() async {
    if (_allInvoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No invoices available to export.')),
      );
      return;
    }
    final csvPath = await CsvService.exportInvoicesToCsv(_allInvoices, _currencySymbol);
    await ShareService.shareFile(
      csvPath,
      text: 'Exported invoice list CSV report.',
      subject: 'Invoice Report CSV',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: _exportCsv,
            tooltip: 'Export List as CSV',
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateEditInvoiceScreen()),
              );
              if (created == true) _loadData();
            },
            tooltip: 'New Invoice',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by invoice # or customer name...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _filteredInvoices.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Invoices Found',
                          description: _searchQuery.isNotEmpty
                              ? 'No matching invoices for "$_searchQuery".'
                              : 'Create your first invoice to manage client billing.',
                          buttonText: 'Create Invoice',
                          onButtonPressed: () async {
                            final created = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreateEditInvoiceScreen()),
                            );
                            if (created == true) _loadData();
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _filteredInvoices[index];
                            return InvoiceTile(
                              invoice: invoice,
                              currencySymbol: _currencySymbol,
                              onTap: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InvoiceDetailScreen(invoiceId: invoice.id),
                                  ),
                                );
                                if (updated == true) _loadData();
                              },
                              onEdit: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateEditInvoiceScreen(invoiceToEdit: invoice),
                                  ),
                                );
                                if (updated == true) _loadData();
                              },
                              onDuplicate: () async {
                                final dup = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateEditInvoiceScreen(
                                      invoiceToEdit: invoice,
                                      isDuplicating: true,
                                    ),
                                  ),
                                );
                                if (dup == true) _loadData();
                              },
                              onDelete: () => _confirmDelete(invoice),
                              onShare: () async {
                                final settings = await _dbService.getAppSettings();
                                final pdfBytes = await PdfBuilder.buildPdf(
                                  invoice: invoice,
                                  currencySymbol: _currencySymbol,
                                  template: settings.pdfTemplate,
                                );
                                await ShareService.shareBytes(
                                  pdfBytes,
                                  'Invoice_${invoice.invoiceNumber}.pdf',
                                  text: 'Invoice #${invoice.invoiceNumber} for ${Formatters.currency(invoice.grandTotal, symbol: _currencySymbol)}',
                                );
                              },
                              onStatusChange: (newStatus) async {
                                await _dbService.updateInvoiceStatus(invoice.id, newStatus);
                                _loadData();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

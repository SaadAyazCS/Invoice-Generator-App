import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/invoice_tile.dart';
import '../widgets/revenue_chart.dart';
import '../widgets/summary_card.dart';
import 'create_edit_invoice_screen.dart';
import 'customer_list_screen.dart';
import 'invoice_detail_screen.dart';
import 'invoice_list_screen.dart';
import 'product_catalog_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const DashboardScreen({super.key, required this.onThemeChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dbService = DatabaseService();

  List<Invoice> _invoices = [];
  String _currencySymbol = '\$';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _dbService.getAppSettings();
      final list = await _dbService.getAllInvoices();
      if (mounted) {
        setState(() {
          _currencySymbol = settings.currency;
          _invoices = list;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Analytics helper calculations
  int get _totalInvoicesCount => _invoices.length;

  int get _paidCount => _invoices.where((i) => i.effectiveStatus == 'Paid').length;
  double get _paidAmount => _invoices
      .where((i) => i.effectiveStatus == 'Paid')
      .fold(0.0, (sum, i) => sum + i.grandTotal);

  int get _unpaidCount => _invoices.where((i) => i.effectiveStatus == 'Unpaid').length;
  double get _unpaidAmount => _invoices
      .where((i) => i.effectiveStatus == 'Unpaid')
      .fold(0.0, (sum, i) => sum + i.grandTotal);

  int get _overdueCount => _invoices.where((i) => i.effectiveStatus == 'Overdue').length;
  double get _overdueAmount => _invoices
      .where((i) => i.effectiveStatus == 'Overdue')
      .fold(0.0, (sum, i) => sum + i.grandTotal);

  double get _totalRevenue => _paidAmount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(38),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Invoice Generator', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerListScreen()),
              );
            },
            tooltip: 'Customers',
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductCatalogScreen()),
              );
            },
            tooltip: 'Products',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(onThemeChanged: widget.onThemeChanged),
                ),
              );
              _loadDashboardData();
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEditInvoiceScreen()),
          );
          if (created == true) _loadDashboardData();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Invoice'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Grid (Total Revenue, Paid, Unpaid, Overdue)
                    GridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        SummaryCard(
                          title: 'Total Revenue',
                          value: Formatters.currency(_totalRevenue, symbol: _currencySymbol),
                          countText: '$_totalInvoicesCount Invoices',
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppTheme.primaryColor,
                          onTap: () => _navigateToInvoices(),
                        ),
                        SummaryCard(
                          title: 'Paid Invoices',
                          value: Formatters.currency(_paidAmount, symbol: _currencySymbol),
                          countText: '$_paidCount Paid',
                          icon: Icons.check_circle_rounded,
                          color: AppTheme.paidColor,
                          onTap: () => _navigateToInvoices('Paid'),
                        ),
                        SummaryCard(
                          title: 'Unpaid Invoices',
                          value: Formatters.currency(_unpaidAmount, symbol: _currencySymbol),
                          countText: '$_unpaidCount Pending',
                          icon: Icons.hourglass_top_rounded,
                          color: AppTheme.unpaidColor,
                          onTap: () => _navigateToInvoices('Unpaid'),
                        ),
                        SummaryCard(
                          title: 'Overdue Invoices',
                          value: Formatters.currency(_overdueAmount, symbol: _currencySymbol),
                          countText: '$_overdueCount Overdue',
                          icon: Icons.warning_amber_rounded,
                          color: AppTheme.overdueColor,
                          onTap: () => _navigateToInvoices('Overdue'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Monthly Revenue Breakdown Chart Widget
                    RevenueChart(
                      invoices: _invoices,
                      currencySymbol: _currencySymbol,
                    ),

                    const SizedBox(height: 24),

                    // Quick Action Buttons Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _quickActionButton(
                            context: context,
                            label: 'New Invoice',
                            icon: Icons.add_rounded,
                            color: AppTheme.primaryColor,
                            onTap: () async {
                              final created = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CreateEditInvoiceScreen()),
                              );
                              if (created == true) _loadDashboardData();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _quickActionButton(
                            context: context,
                            label: 'Customers',
                            icon: Icons.contacts_rounded,
                            color: AppTheme.secondaryColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CustomerListScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _quickActionButton(
                            context: context,
                            label: 'Products',
                            icon: Icons.inventory_2_rounded,
                            color: AppTheme.accentColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProductCatalogScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent Invoices Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Invoices',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _navigateToInvoices(),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_invoices.isEmpty)
                      EmptyStateWidget(
                        title: 'No Invoices Yet',
                        description: 'Create professional invoices for your clients with automatic tax and total calculations.',
                        buttonText: 'Create First Invoice',
                        onButtonPressed: () async {
                          final created = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateEditInvoiceScreen()),
                          );
                          if (created == true) _loadDashboardData();
                        },
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _invoices.length > 5 ? 5 : _invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = _invoices[index];
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
                              if (updated == true) _loadDashboardData();
                            },
                            onEdit: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateEditInvoiceScreen(invoiceToEdit: invoice),
                                ),
                              );
                              if (updated == true) _loadDashboardData();
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
                              if (dup == true) _loadDashboardData();
                            },
                            onDelete: () async {
                              await _dbService.deleteInvoice(invoice.id);
                              _loadDashboardData();
                            },
                            onShare: () {},
                            onStatusChange: (newStatus) async {
                              await _dbService.updateInvoiceStatus(invoice.id, newStatus);
                              _loadDashboardData();
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  void _navigateToInvoices([String? filter]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceListScreen(initialFilter: filter),
      ),
    );
    _loadDashboardData();
  }

  Widget _quickActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

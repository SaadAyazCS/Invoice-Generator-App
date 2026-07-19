import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/empty_state_widget.dart';

class CustomerListScreen extends StatefulWidget {
  final bool isSelectionMode;

  const CustomerListScreen({super.key, this.isSelectionMode = false});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _dbService = DatabaseService();
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final list = await _dbService.getAllCustomers();
    setState(() {
      _customers = list;
      _applySearch();
      _isLoading = false;
    });
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      _filteredCustomers = _customers.where((c) {
        return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.phone.contains(_searchQuery);
      }).toList();
    }
  }

  void _showAddEditCustomerDialog([Customer? customer]) {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final addressController = TextEditingController(text: customer?.address ?? '');
    final emailController = TextEditingController(text: customer?.email ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    bool isFavorite = customer?.isFavorite ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(customer == null ? 'Add New Customer' : 'Edit Customer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Customer Name *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Mark as Favorite Customer'),
                      value: isFavorite,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setModalState(() => isFavorite = val ?? false);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    final newCust = Customer(
                      id: customer?.id,
                      name: nameController.text.trim(),
                      address: addressController.text.trim(),
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                      isFavorite: isFavorite,
                    );

                    if (customer == null) {
                      await _dbService.insertCustomer(newCust);
                    } else {
                      await _dbService.updateCustomer(newCust);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      _loadCustomers();
                    }
                  },
                  child: Text(customer == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'Select Customer' : 'Customer History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _showAddEditCustomerDialog(),
            tooltip: 'Add Customer',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search customer by name, email, phone...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _applySearch();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _filteredCustomers.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Customers Found',
                          description: 'Add customers to build your client catalog for 1-click invoice creation.',
                          icon: Icons.people_outline_rounded,
                          buttonText: 'Add First Customer',
                          onButtonPressed: () => _showAddEditCustomerDialog(),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                                  child: Text(
                                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      customer.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    if (customer.isFavorite) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (customer.email.isNotEmpty) Text(customer.email, style: const TextStyle(fontSize: 12)),
                                    if (customer.phone.isNotEmpty) Text(customer.phone, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                trailing: widget.isSelectionMode
                                    ? const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor)
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20),
                                            onPressed: () => _showAddEditCustomerDialog(customer),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.overdueColor, size: 20),
                                            onPressed: () async {
                                              await _dbService.deleteCustomer(customer.id);
                                              _loadCustomers();
                                            },
                                          ),
                                        ],
                                      ),
                                onTap: widget.isSelectionMode
                                    ? () => Navigator.pop(context, customer)
                                    : () => _showAddEditCustomerDialog(customer),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

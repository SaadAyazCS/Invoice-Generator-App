import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/company_profile.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/product_item_form.dart';
import 'customer_list_screen.dart';
import 'product_catalog_screen.dart';

class CreateEditInvoiceScreen extends StatefulWidget {
  final Invoice? invoiceToEdit;
  final bool isDuplicating;

  const CreateEditInvoiceScreen({
    super.key,
    this.invoiceToEdit,
    this.isDuplicating = false,
  });

  @override
  State<CreateEditInvoiceScreen> createState() => _CreateEditInvoiceScreenState();
}

class _CreateEditInvoiceScreenState extends State<CreateEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  late String _invoiceNumber;
  late DateTime _invoiceDate;
  late DateTime _dueDate;

  // Customer Controllers
  late TextEditingController _custNameCtrl;
  late TextEditingController _custAddressCtrl;
  late TextEditingController _custEmailCtrl;
  late TextEditingController _custPhoneCtrl;

  // Notes & Tax Controllers
  late TextEditingController _notesCtrl;
  late TextEditingController _taxRateCtrl;

  CompanyProfile _businessInfo = CompanyProfile();
  AppSettings _settings = AppSettings();
  List<InvoiceItem> _items = [];
  String _status = 'Unpaid';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _custNameCtrl = TextEditingController();
    _custAddressCtrl = TextEditingController();
    _custEmailCtrl = TextEditingController();
    _custPhoneCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _taxRateCtrl = TextEditingController();

    _invoiceDate = DateTime.now();
    _dueDate = DateTime.now().add(const Duration(days: 14));
    _invoiceNumber = 'INV-001';

    _initFormData();
  }

  Future<void> _initFormData() async {
    setState(() => _isLoading = true);
    try {
      _businessInfo = await _dbService.getCompanyProfile();
      _settings = await _dbService.getAppSettings();

      if (widget.invoiceToEdit != null) {
        final inv = widget.invoiceToEdit!;
        if (widget.isDuplicating) {
          _invoiceNumber = await _dbService.generateNextInvoiceNumber();
          _status = 'Unpaid';
        } else {
          _invoiceNumber = inv.invoiceNumber;
          _status = inv.status;
        }

        _invoiceDate = inv.invoiceDate;
        _dueDate = inv.dueDate;
        _businessInfo = inv.businessInfo;
        _custNameCtrl.text = inv.customerInfo.name;
        _custAddressCtrl.text = inv.customerInfo.address;
        _custEmailCtrl.text = inv.customerInfo.email;
        _custPhoneCtrl.text = inv.customerInfo.phone;
        _notesCtrl.text = inv.notes;
        _taxRateCtrl.text = inv.taxRate.toStringAsFixed(1);
        _items = List.from(inv.items.map((i) => i.copyWith()));
      } else {
        _invoiceNumber = await _dbService.generateNextInvoiceNumber();
        _taxRateCtrl.text = _settings.defaultTaxRate.toStringAsFixed(1);
        _items = [
          InvoiceItem(name: 'Item / Service Description', quantity: 1, unitPrice: 100.0)
        ];
      }
    } catch (e) {
      debugPrint('Error initializing form data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + i.itemTotal);
  double get _totalDiscount => _items.fold(0.0, (sum, i) => sum + i.discountAmount);
  double get _taxRate => double.tryParse(_taxRateCtrl.text.trim()) ?? 0.0;
  double get _taxAmount => _subtotal * (_taxRate / 100.0);
  double get _grandTotal => _subtotal + _taxAmount;

  Future<void> _selectDate(bool isDueDate) async {
    final initialDate = isDueDate ? _dueDate : _invoiceDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _invoiceDate = picked;
        }
      });
    }
  }

  Future<void> _pickCustomerFromCatalog() async {
    final Customer? selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerListScreen(isSelectionMode: true)),
    );
    if (selected != null) {
      setState(() {
        _custNameCtrl.text = selected.name;
        _custAddressCtrl.text = selected.address;
        _custEmailCtrl.text = selected.email;
        _custPhoneCtrl.text = selected.phone;
      });
    }
  }

  Future<void> _pickProductFromCatalog() async {
    final Product? selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductCatalogScreen(isSelectionMode: true)),
    );
    if (selected != null) {
      setState(() {
        _items.add(InvoiceItem(
          name: selected.name,
          quantity: 1,
          unitPrice: selected.unitPrice,
        ));
      });
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the validation errors in the form.'),
          backgroundColor: AppTheme.overdueColor,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item or service line.'),
          backgroundColor: AppTheme.overdueColor,
        ),
      );
      return;
    }

    final invoice = Invoice(
      id: (widget.invoiceToEdit != null && !widget.isDuplicating)
          ? widget.invoiceToEdit!.id
          : null,
      invoiceNumber: _invoiceNumber,
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      businessInfo: _businessInfo,
      customerInfo: Customer(
        name: _custNameCtrl.text.trim(),
        address: _custAddressCtrl.text.trim(),
        email: _custEmailCtrl.text.trim(),
        phone: _custPhoneCtrl.text.trim(),
      ),
      items: _items,
      taxRate: _taxRate,
      notes: _notesCtrl.text.trim(),
      status: _status,
    );

    if (widget.invoiceToEdit != null && !widget.isDuplicating) {
      await _dbService.updateInvoice(invoice);
    } else {
      await _dbService.insertInvoice(invoice);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoiceToEdit == null
            ? 'Create New Invoice'
            : (widget.isDuplicating ? 'Duplicate Invoice' : 'Edit Invoice')),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveInvoice,
            tooltip: 'Save Invoice',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar (Invoice Number & Status)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor.withAlpha(77)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Invoice Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                _invoiceNumber,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                          DropdownButton<String>(
                            value: _status,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
                              DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                              DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Date Pickers Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Invoice Date',
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                              ),
                              child: Text(Formatters.dateShort(_invoiceDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Due Date',
                                prefixIcon: Icon(Icons.event_available_rounded),
                              ),
                              child: Text(Formatters.dateShort(_dueDate)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Customer Details Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Customer Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                        TextButton.icon(
                          onPressed: _pickCustomerFromCatalog,
                          icon: const Icon(Icons.contacts_rounded, size: 16),
                          label: const Text('Pick Customer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _custNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Customer / Client Name *',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (val) => Validators.requiredField(val, 'Customer name'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _custAddressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Billing Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _custEmailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: Validators.email,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _custPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Line Items Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Items & Services',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor),
                              onPressed: _pickProductFromCatalog,
                              tooltip: 'Import from Product Catalog',
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _items.add(InvoiceItem(name: '', quantity: 1, unitPrice: 0.0));
                                });
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Item'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return ProductItemForm(
                        index: idx,
                        item: item,
                        currencySymbol: _settings.currency,
                        onChanged: (newItem) {
                          setState(() {
                            _items[idx] = newItem;
                          });
                        },
                        onDelete: () {
                          setState(() {
                            _items.removeAt(idx);
                          });
                        },
                      );
                    }),

                    const SizedBox(height: 20),

                    // Calculation Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text(
                                Formatters.currency(_subtotal, symbol: _settings.currency),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (_totalDiscount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Discount:'),
                                Text(
                                  '-${Formatters.currency(_totalDiscount, symbol: _settings.currency)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.paidColor),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _taxRateCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Tax Rate (%)',
                                    isDense: true,
                                  ),
                                  onChanged: (val) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Tax Amount:', style: TextStyle(fontSize: 12)),
                                    Text(
                                      Formatters.currency(_taxAmount, symbol: _settings.currency),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                              Text(
                                Formatters.currency(_grandTotal, symbol: _settings.currency),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Notes & Payment Instructions
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes or Payment Instructions',
                        hintText: 'Thank you for your business! Payment due within 14 days.',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveInvoice,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save & View Invoice'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

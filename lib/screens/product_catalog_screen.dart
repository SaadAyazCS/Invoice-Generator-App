import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state_widget.dart';

class ProductCatalogScreen extends StatefulWidget {
  final bool isSelectionMode;

  const ProductCatalogScreen({super.key, this.isSelectionMode = false});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _dbService = DatabaseService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _dbService.getAppSettings();
      final list = await _dbService.getAllProducts();
      if (mounted) {
        setState(() {
          _currencySymbol = settings.currency;
          _products = list;
          _applySearch();
        });
      }
    } catch (e) {
      debugPrint('Error loading product catalog: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = _products.where((p) {
        return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  void _showAddEditProductDialog([Product? product]) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product != null ? product.unitPrice.toStringAsFixed(2) : '');
    final unitController = TextEditingController(text: product?.unit ?? 'pcs');
    final descController = TextEditingController(text: product?.description ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Add Product / Service' : 'Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: 'Price ($_currencySymbol) *'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
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
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                if (name.isEmpty || price <= 0) return;

                final newProd = Product(
                  id: product?.id,
                  name: name,
                  unitPrice: price,
                  unit: unitController.text.trim(),
                  description: descController.text.trim(),
                );

                if (product == null) {
                  await _dbService.insertProduct(newProd);
                } else {
                  await _dbService.updateProduct(newProd);
                }

                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: Text(product == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'Select Product' : 'Product Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_rounded),
            onPressed: () => _showAddEditProductDialog(),
            tooltip: 'Add Product',
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
                      hintText: 'Search product or service...',
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
                  child: _filteredProducts.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Products in Catalog',
                          description: 'Save standard items or services to easily insert them into future invoices.',
                          icon: Icons.inventory_2_outlined,
                          buttonText: 'Add First Product',
                          onButtonPressed: () => _showAddEditProductDialog(),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
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
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.secondaryColor),
                                ),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  product.description.isNotEmpty ? product.description : 'Unit: ${product.unit}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${Formatters.currency(product.unitPrice, symbol: _currencySymbol)} / ${product.unit}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    if (widget.isSelectionMode)
                                      const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor)
                                    else ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        onPressed: () => _showAddEditProductDialog(product),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.overdueColor, size: 20),
                                        onPressed: () async {
                                          await _dbService.deleteProduct(product.id);
                                          _loadData();
                                        },
                                      ),
                                    ]
                                  ],
                                ),
                                onTap: widget.isSelectionMode
                                    ? () => Navigator.pop(context, product)
                                    : () => _showAddEditProductDialog(product),
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

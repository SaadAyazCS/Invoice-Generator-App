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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(product == null ? 'Add Product / Service' : 'Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product / Service Name *'),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
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

                final nav = Navigator.of(context);
                if (product == null) {
                  await _dbService.insertProduct(newProd);
                } else {
                  await _dbService.updateProduct(newProd);
                }

                if (mounted) {
                  nav.pop();
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditProductDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
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
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x08000000),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: widget.isSelectionMode
                                    ? () => Navigator.pop(context, product)
                                    : () => _showAddEditProductDialog(product),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryColor.withAlpha(38),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.secondaryColor, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product.description.isNotEmpty
                                                  ? product.description
                                                  : 'Unit: ${product.unit}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${Formatters.currency(product.unitPrice, symbol: _currencySymbol)} / ${product.unit}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (widget.isSelectionMode)
                                        const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor, size: 24)
                                      else
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert_rounded,
                                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          ),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          onSelected: (val) async {
                                            if (val == 'edit') {
                                              _showAddEditProductDialog(product);
                                            } else if (val == 'delete') {
                                              await _dbService.deleteProduct(product.id);
                                              _loadData();
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 18),
                                                  SizedBox(width: 10),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline_rounded, color: AppTheme.overdueColor, size: 18),
                                                  SizedBox(width: 10),
                                                  Text('Delete', style: TextStyle(color: AppTheme.overdueColor)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
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

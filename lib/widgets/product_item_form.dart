import 'package:flutter/material.dart';
import '../models/invoice_item.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class ProductItemForm extends StatelessWidget {
  final int index;
  final InvoiceItem item;
  final String currencySymbol;
  final ValueChanged<InvoiceItem> onChanged;
  final VoidCallback onDelete;

  const ProductItemForm({
    super.key,
    required this.index,
    required this.item,
    required this.currencySymbol,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.overdueColor, size: 20),
                onPressed: onDelete,
                tooltip: 'Remove Item',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.name,
            decoration: const InputDecoration(
              hintText: 'Product or Service Name',
              isDense: true,
            ),
            onChanged: (val) {
              onChanged(item.copyWith(name: val));
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final qty = int.tryParse(val) ?? 1;
                    onChanged(item.copyWith(quantity: qty));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: item.unitPrice > 0 ? item.unitPrice.toStringAsFixed(2) : '',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price ($currencySymbol)',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final price = double.tryParse(val) ?? 0.0;
                    onChanged(item.copyWith(unitPrice: price));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: item.discountPercent > 0 ? item.discountPercent.toStringAsFixed(0) : '',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Disc %',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final disc = double.tryParse(val) ?? 0.0;
                    onChanged(item.copyWith(discountPercent: disc));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ${Formatters.currency(item.itemTotal, symbol: currencySymbol)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class RevenueChart extends StatelessWidget {
  final List<Invoice> invoices;
  final String currencySymbol;

  const RevenueChart({
    super.key,
    required this.invoices,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group paid revenue by past 6 months
    final now = DateTime.now();
    final List<Map<String, dynamic>> monthlyData = [];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthName = _monthAbbr(monthDate.month);

      double sum = 0.0;
      for (var inv in invoices) {
        if (inv.effectiveStatus == 'Paid') {
          if (inv.invoiceDate.year == monthDate.year && inv.invoiceDate.month == monthDate.month) {
            sum += inv.grandTotal;
          }
        }
      }
      monthlyData.add({'month': monthName, 'amount': sum});
    }

    final double maxAmount = monthlyData.fold(
      0.0,
      (max, item) => (item['amount'] as double) > max ? item['amount'] as double : max,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paid revenue over the last 6 months',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyData.map((data) {
                final double amount = data['amount'];
                final String month = data['month'];
                final double heightFactor = maxAmount > 0 ? (amount / maxAmount) : 0.05;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (amount > 0)
                      Text(
                        Formatters.currency(amount, symbol: currencySymbol)
                            .replaceAll('.00', ''),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      width: 24,
                      height: (100 * heightFactor).clamp(8.0, 100.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      month,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

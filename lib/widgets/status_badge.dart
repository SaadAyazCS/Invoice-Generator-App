import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isLarge;

  const StatusBadge({
    super.key,
    required this.status,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'paid':
        bg = AppTheme.paidColor.withAlpha(38);
        fg = AppTheme.paidColor;
        icon = Icons.check_circle_rounded;
        break;
      case 'overdue':
        bg = AppTheme.overdueColor.withAlpha(38);
        fg = AppTheme.overdueColor;
        icon = Icons.warning_amber_rounded;
        break;
      case 'unpaid':
      default:
        bg = AppTheme.unpaidColor.withAlpha(38);
        fg = AppTheme.unpaidColor;
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withAlpha(77), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isLarge ? 16 : 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: isLarge ? 12 : 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

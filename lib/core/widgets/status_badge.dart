import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color _getStatusColor() {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'pending') return const Color(0xFFFBC02D); // Amber
    if (lowerStatus == 'under investigation') return AppTheme.accentOrange;
    if (lowerStatus == 'settled') return AppTheme.laurelGreen;
    if (lowerStatus == 'closed') return AppTheme.slateGray;
    return AppTheme.darkNavy;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

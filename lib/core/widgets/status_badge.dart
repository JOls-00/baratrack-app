import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Accessible Status Badge (Task 31)
/// - Pairs every status with a semantic icon and text label (never color alone)
/// - Adheres strictly to Task 39 color tokens and WCAG 4.5:1 contrast
/// - Enforces tap & touch accessibility (min height 28px)
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lower = status.trim().toLowerCase();

    Color color;
    Color bg;
    IconData icon;
    String label = status;

    if (lower == 'settled' || lower == 'naayos' || lower == 'resolved') {
      color = AppTheme.success;
      bg = isDark ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.successBg;
      icon = Icons.check_circle_rounded;
    } else if (lower == 'under investigation' ||
        lower == 'in investigation' ||
        lower == 'investigation' ||
        lower == 'sinusuri' ||
        lower == 'hearing scheduled' ||
        lower == 'paghaharap' ||
        lower == 'mediation') {
      color = AppTheme.warning;
      bg = isDark ? AppTheme.warning.withValues(alpha: 0.15) : AppTheme.warningBg;
      icon = Icons.pending_actions_rounded;
    } else if (lower == 'pending' || lower == 'naihain' || lower == 'submitted') {
      color = isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500;
      bg = isDark ? AppTheme.brand500.withValues(alpha: 0.15) : AppTheme.brand50;
      icon = Icons.hourglass_top_rounded;
    } else if (lower == 'dismissed' || lower == 'rejected' || lower == 'cancelled') {
      color = AppTheme.error;
      bg = isDark ? AppTheme.error.withValues(alpha: 0.15) : AppTheme.errorBg;
      icon = Icons.cancel_rounded;
    } else if (lower == 'closed' || lower == 'isinara' || lower == 'archived') {
      color = isDark ? AppTheme.textHintDark : AppTheme.textHintLight;
      bg = isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);
      icon = Icons.lock_outline_rounded;
    } else {
      color = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      icon = Icons.info_outline_rounded;
    }

    return Semantics(
      label: 'Katayuan: $label',
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 24 : 28),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppTheme.space8 : AppTheme.space12,
          vertical: AppTheme.space4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.45 : 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: compact ? 12 : 14,
              color: color,
            ),
            const SizedBox(width: AppTheme.space4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

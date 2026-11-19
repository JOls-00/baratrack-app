import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/branding_provider.dart';
import '../../providers/locale_provider.dart';
import '../../../config/app_theme.dart';
import '../../../data/models/hearing_model.dart';

class HearingDetailsDialog {
  static String _presidingOfficer(BuildContext context) {
    try {
      final officials = context.read<BrandingProvider>().officials;
      for (final o in officials) {
        if (o.group == 'captain' || o.position.toLowerCase().contains('punong barangay')) {
          return o.name.startsWith('Hon.') ? o.name : 'Hon. ${o.name}';
        }
      }
    } catch (_) {}
    return 'Hon. Judy R. Balberan (Punong Barangay)';
  }

  static (DateTime startUtc, DateTime endUtc) _computeUtcRange(DateTime date, String rawTime) {
    int hour = 9;
    int minute = 0;
    final m = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$', caseSensitive: false)
        .firstMatch(rawTime.trim());
    if (m != null) {
      hour = int.tryParse(m.group(1)!) ?? 9;
      minute = int.tryParse(m.group(2)!) ?? 0;
      final ap = m.group(3)?.toUpperCase();
      if (ap == 'PM' && hour < 12) hour += 12;
      if (ap == 'AM' && hour == 12) hour = 0;
    }
    // Philippines Time (UTC+8): subtract 8 hours to get exact UTC timestamp.
    final localDt = DateTime.utc(date.year, date.month, date.day, hour, minute);
    final startUtc = localDt.subtract(const Duration(hours: 8));
    final endUtc = startUtc.add(const Duration(hours: 1));
    return (startUtc, endUtc);
  }

  static void show(BuildContext context, HearingModel hearing) {
    final isFil = context.read<LocaleProvider>().isFilipino;
    final theme = Theme.of(context);
    final officer = _presidingOfficer(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFil ? 'Iskedyul ng Pagdinig' : 'Hearing Schedule',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isFil ? 'Sesyon ng Paghaharap' : 'Mediation Session',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.brand),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 32),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDetailRow(ctx, Icons.tag, isFil ? 'Numero ng Kaso' : 'Case Reference', 'Case #${hearing.caseNumber}'),
                    _buildDetailRow(ctx, Icons.calendar_today, isFil ? 'Itinakdang Petsa' : 'Scheduled Date', DateFormat('MMMM dd, yyyy').format(hearing.hearingDate)),
                    _buildDetailRow(ctx, Icons.access_time, isFil ? 'Itinakdang Oras' : 'Scheduled Time', hearing.hearingTime),
                    _buildDetailRow(ctx, Icons.location_on_outlined, isFil ? 'Lugar / Silid' : 'Venue / Room', hearing.venue),
                    _buildDetailRow(ctx, Icons.person_outline, isFil ? 'Namamahalang Opisyal' : 'Presiding Officer', officer),
                    _buildDetailRow(ctx, Icons.info_outline, isFil ? 'Katayuan' : 'Schedule Status', hearing.status, isStatus: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _addToCalendar(ctx, hearing),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                      label: Text(
                        isFil ? 'Idagdag sa Kalendaryo' : 'Add to Calendar',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.brand,
                        side: BorderSide(color: context.brand),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isFil ? 'Naintindihan' : 'Acknowledge', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _addToCalendar(BuildContext context, HearingModel hearing) async {
    try {
      final title = Uri.encodeComponent('Lupon Hearing: Case #${hearing.caseNumber}');
      final details = Uri.encodeComponent('Barangay Rosario Lupon Mediation Session. Venue: ${hearing.venue}. Notes: ${hearing.notes ?? "None"}');
      final location = Uri.encodeComponent(hearing.venue.isNotEmpty ? hearing.venue : 'Barangay Rosario Hall, Santiago City');
      final (startUtc, endUtc) = _computeUtcRange(hearing.hearingDate, hearing.hearingTime);
      final fmt = DateFormat("yyyyMMdd'T'HHmmss'Z'");
      final dates = '${fmt.format(startUtc)}/${fmt.format(endUtc)}';

      final calUrl = Uri.parse(
        'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&dates=$dates&details=$details&location=$location',
      );
      if (await canLaunchUrl(calUrl)) {
        await launchUrl(calUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          final isFil = context.read<LocaleProvider>().isFilipino;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isFil ? 'Hindi mabuksan ang kalendaryo sa device.' : 'Could not open the calendar app on this device.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        final isFil = context.read<LocaleProvider>().isFilipino;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isFil ? 'May naganap na error sa pagbukas ng kalendaryo.' : 'An error occurred while opening the calendar.')),
        );
      }
    }
  }

  static Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {bool isStatus = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.brand),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isStatus ? AppTheme.accentOrange : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

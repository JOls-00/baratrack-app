import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_theme.dart';

class EmergencyHotline {
  final String title;
  final String agency;
  final String phoneNumber;
  final String displayPhone;
  final IconData icon;
  final String description;

  const EmergencyHotline({
    required this.title,
    required this.agency,
    required this.phoneNumber,
    required this.displayPhone,
    required this.icon,
    required this.description,
  });
}

class EmergencyHotlinesModal extends StatelessWidget {
  const EmergencyHotlinesModal({super.key});

  static const List<EmergencyHotline> hotlines = [
    EmergencyHotline(
      title: 'Barangay Rosario Peace & Order',
      agency: 'Barangay Hall / Tanod Desk',
      phoneNumber: '09171234567',
      displayPhone: '0917-123-4567',
      icon: Icons.shield_outlined,
      description: 'Barangay Tanod response, blotter, & immediate neighborhood assistance',
    ),
    EmergencyHotline(
      title: 'Santiago City CDRRMO / Rescue 1021',
      agency: 'Disaster Risk Reduction & Medical Emergency',
      phoneNumber: '09178141021',
      displayPhone: '0917-814-1021 / (078) 305-1021',
      icon: Icons.medical_services_outlined,
      description: 'Ambulance, vehicular accidents, rescue operations, & typhoons',
    ),
    EmergencyHotline(
      title: 'Santiago City Police Station (PNP)',
      agency: 'Philippine National Police - Station 1',
      phoneNumber: '09985987711',
      displayPhone: '0998-598-7711 / (078) 305-1234',
      icon: Icons.local_police_outlined,
      description: 'Criminal incidents, urgent security threats, & police response',
    ),
    EmergencyHotline(
      title: 'Santiago City Fire Station (BFP)',
      agency: 'Bureau of Fire Protection',
      phoneNumber: '09274635494',
      displayPhone: '0927-463-5494 / (078) 305-0160',
      icon: Icons.local_fire_department_outlined,
      description: 'Fire suppression, hazardous material spills, & structural collapse',
    ),
  ];

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const EmergencyHotlinesModal(),
    );
  }

  Future<void> _call(BuildContext context, String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot launch phone dialer for $phoneNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.brand500.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_in_talk_rounded,
                  color: isDark ? const Color(0xFFFF6B6E) : AppTheme.brand500,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Hotlines',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available 24/7 • Works completely offline',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hotline list
          for (final h in hotlines) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Icon(
                      h.icon,
                      color: isDark ? const Color(0xFFFF6B6E) : AppTheme.brand500,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          h.displayPhone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFFF6B6E) : AppTheme.brand500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          h.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brand500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.call, size: 16),
                      label: const Text('Call', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => _call(context, h.phoneNumber),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

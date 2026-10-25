import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../data/models/hearing_model.dart';

class HearingDetailsDialog {
  static void show(BuildContext context, HearingModel hearing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hearing Schedule', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    Text('Mediation Session', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.brand)),
                  ],
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 40),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDetailRow(context, Icons.tag, 'Case Reference', 'Case #${hearing.caseNumber}'),
                    _buildDetailRow(context, Icons.calendar_today, 'Scheduled Date', DateFormat('MMMM dd, yyyy').format(hearing.hearingDate)),
                    _buildDetailRow(context, Icons.access_time, 'Scheduled Time', hearing.hearingTime),
                    _buildDetailRow(context, Icons.location_on_outlined, 'Venue / Room', hearing.venue),
                    _buildDetailRow(context, Icons.person_outline, 'Presiding Officer', 'P/Bgy. Pedro Penduko'),
                    _buildDetailRow(context, Icons.info_outline, 'Schedule Status', hearing.status, isStatus: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: context.brand, foregroundColor: Colors.white),
                child: const Text('Acknowledge Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.brand),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text(
                  value, 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: isStatus ? AppTheme.accentOrange : AppTheme.textDark
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

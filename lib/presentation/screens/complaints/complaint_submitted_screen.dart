import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';

/// Screen displayed after a resident successfully submits a complaint (Task 32).
/// Displays:
/// - Official Case Reference Number / Tracking ID
/// - 1-tap Copy & Share buttons
/// - Short summary of the filed complaint
/// - Guidance on Lupon mediation next steps
class ComplaintSubmittedScreen extends StatelessWidget {
  final int complaintId;
  final String? caseNumber;
  final String category;
  final String respondentName;
  final String location;
  final String incidentDate;
  final String incidentTime;
  final int evidenceCount;

  const ComplaintSubmittedScreen({
    super.key,
    required this.complaintId,
    this.caseNumber,
    required this.category,
    required this.respondentName,
    required this.location,
    required this.incidentDate,
    required this.incidentTime,
    this.evidenceCount = 0,
  });

  String get _referenceCode {
    if (caseNumber != null && caseNumber!.trim().isNotEmpty) {
      return caseNumber!;
    }
    final year = DateTime.now().year;
    final idStr = complaintId.abs().toString().padLeft(4, '0');
    return 'ROS-$year-$idStr';
  }

  String get _formattedSummary {
    return '''
BARANGAY ROSARIO BLOTTER & COMPLAINT SYSTEM
========================================
Tracking Reference: $_referenceCode
Kategorya: $category
Inirereklamo: $respondentName
Petsa at Oras: $incidentDate, $incidentTime
Lokasyon: $location
Attached Evidence: $evidenceCount file(s)
Katayuan: Naihain / For Review ng Lupon

Mangyaring itabi ang reference code na ito para sa pag-track ng inyong reklamo.
''';
  }

  void _copyReference(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _referenceCode));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppTheme.space8),
            Text('Nakopya ang Reference Code: $_referenceCode'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareSummary(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _formattedSummary));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.content_paste_rounded, color: Colors.white, size: 20),
            SizedBox(width: AppTheme.space8),
            Expanded(
              child: Text(
                'Nakopya ang buod sa clipboard! Maaari mo na itong i-paste sa SMS o chat.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.brand700,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sideMargin = AppTheme.sideMargin(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/my-complaints');
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.scaffoldDark : AppTheme.scaffoldLight,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Katibayan ng Paghain'),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: sideMargin, vertical: AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Success Header
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.success.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Icon(Icons.check_circle_rounded, size: 44, color: AppTheme.success),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                Text(
                  'Matagumpay na Naihain!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  'Opisyal nang naitala ang iyong reklamo sa Barangay Rosario.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Case Reference Code Box
                Container(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'CASE REFERENCE / TRACKING NUMBER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? AppTheme.textHintDark : AppTheme.textHintLight,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      SelectableText(
                        _referenceCode,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      // Copy & Share Action Buttons (Min height 44px)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton.icon(
                                onPressed: () => _copyReference(context),
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Kopyahin', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500,
                                  side: BorderSide(
                                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () => _shareSummary(context),
                                icon: const Icon(Icons.share_rounded, size: 16),
                                label: const Text('Ibahagi', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.brand500,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                // Complaint Summary Card
                Container(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 18,
                            color: isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500,
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Text(
                            'Buod ng Reklamo',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _summaryRow('Kategorya:', category, isDark),
                      const SizedBox(height: AppTheme.space8),
                      _summaryRow('Inirereklamo:', respondentName, isDark),
                      const SizedBox(height: AppTheme.space8),
                      _summaryRow('Petsa at Oras:', '$incidentDate, $incidentTime', isDark),
                      const SizedBox(height: AppTheme.space8),
                      _summaryRow('Lugar:', location, isDark),
                      if (evidenceCount > 0) ...[
                        const SizedBox(height: AppTheme.space8),
                        _summaryRow('Ebidensya:', '$evidenceCount file(s) kalakip', isDark),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                // Next Steps Card
                Container(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.warning),
                          const SizedBox(width: AppTheme.space8),
                          Text(
                            'Ano ang susunod na hakbang?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        '1. Sinusuri ng Barangay Desk Officer ang mga detalye at ebidensya sa loob ng 24–48 oras.\n'
                        '2. Ipapadala ang abiso sa inyo at sa inirereklamo para sa mediation o pagdinig sa Lupon Tagapamayapa.\n'
                        '3. Maaari mong subaybayan ang galaw ng kaso sa tab na "Reklamo".',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Primary Bottom Action
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/my-complaints');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brand500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'TINGNAN ANG AKING MGA REKLAMO',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                SizedBox(
                  height: 44,
                  child: TextButton(
                    onPressed: () {
                      context.go('/');
                    },
                    child: Text(
                      'Bumalik sa Home',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.textHintDark : AppTheme.textHintLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

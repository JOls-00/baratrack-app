import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/case_model.dart';
import '../../../data/models/hearing_model.dart';
import '../../../data/repositories/offline_queue_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/hearing_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../walkthrough/walkthrough_screen.dart';
import '../complaints/file_complaint_screen.dart';

/// Resident Home Screen (Task 27)
/// Features:
/// - Unsent offline drafts reminder banner (when unsent drafts exist)
/// - One main action card "File a complaint" (Maghain ng Reklamo)
/// - Next upcoming hearing card
/// - Active case timeline / status overview
class UserDashboardView extends StatefulWidget {
  const UserDashboardView({super.key});

  @override
  State<UserDashboardView> createState() => _UserDashboardViewState();
}

class _UserDashboardViewState extends State<UserDashboardView> {
  bool _narrow = false;
  int _unsentDraftsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ComplaintProvider>().fetchMyComplaints();
        context.read<HearingProvider>().fetchHearings();
        _checkDrafts();
        _checkFirstTimeWalkthrough();
      }
    });
  }

  Future<void> _checkFirstTimeWalkthrough() async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getBool('walkthrough_seen_${user.id}') ?? false;
        if (!seen && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WalkthroughScreen()),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _checkDrafts() async {
    try {
      final repo = context.read<OfflineQueueRepository>();
      final items = await repo.getAll();
      final count = items.where((d) =>
          d.type == 'complaint' &&
          (d.state == 'draft' || d.state == 'failed' || d.state == 'pending')).length;
      if (mounted) {
        setState(() => _unsentDraftsCount = count);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    _narrow = MediaQuery.of(context).size.width < 700;
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final complaintProvider = context.watch<ComplaintProvider>();
    final complaints = complaintProvider.myComplaints;
    final sideMargin = AppTheme.sideMargin(context);

    // Active complaint
    ComplaintModel? activeComplaint;
    if (complaints.isNotEmpty) {
      try {
        activeComplaint = complaints.firstWhere(
          (c) => c.caseId != null && c.status != 'Settled' && c.status != 'Closed',
        );
      } catch (_) {
        activeComplaint = complaints.first;
      }
    }

    // Next upcoming hearing
    final hearingProvider = context.watch<HearingProvider>();
    final hearings = hearingProvider.hearings;
    HearingModel? nextHearing;
    final nowThreshold = DateTime.now().subtract(const Duration(hours: 4));
    for (final h in hearings) {
      if (h.hearingDate.isAfter(nowThreshold)) {
        nextHearing = h;
        break;
      }
    }
    if (nextHearing == null && hearings.isNotEmpty) {
      nextHearing = hearings.first;
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<ComplaintProvider>().fetchMyComplaints(),
          context.read<HearingProvider>().fetchHearings(),
          _checkDrafts(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(sideMargin, AppTheme.space16, sideMargin, AppTheme.space32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Unsent Offline Drafts Reminder Banner (Task 27)
            if (_unsentDraftsCount > 0) ...[
              _buildDraftsReminderBanner(theme, isDark),
              const SizedBox(height: AppTheme.space16),
            ],

            // 2. Main Action Card "File a Complaint" (Task 27)
            _buildMainActionCard(context, theme, user?.name ?? 'Resident', isDark),
            const SizedBox(height: AppTheme.space16),

            // 3. Next Hearing Card (Task 27)
            _buildNextHearingCard(theme, nextHearing, isDark),
            const SizedBox(height: AppTheme.space16),

            // 4. Case Tracking Overview or Emergency Contacts
            if (_narrow) ...[
              if (activeComplaint != null)
                _buildTimelineCard(theme, activeComplaint, isDark)
              else
                _buildNoActiveCaseCard(theme, isDark),
              const SizedBox(height: AppTheme.space16),
              _buildEmergencyContacts(theme, isDark),
              const SizedBox(height: AppTheme.space16),
              _buildProfileCompleteness(theme, user?.residentId != null, isDark),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: activeComplaint != null
                        ? _buildTimelineCard(theme, activeComplaint, isDark)
                        : _buildNoActiveCaseCard(theme, isDark),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildEmergencyContacts(theme, isDark),
                        const SizedBox(height: AppTheme.space16),
                        _buildProfileCompleteness(theme, user?.residentId != null, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Drafts Reminder Banner (Task 27)
  Widget _buildDraftsReminderBanner(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.warning.withValues(alpha: 0.15) : AppTheme.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: isDark ? 0.4 : 0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.warning, size: 24),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mayroon kang $_unsentDraftsCount hindi pa nai-sync na reklamo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  'I-tap para ipadala kapag may internet o suriin ang drafts.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: ElevatedButton(
              onPressed: () {
                context.push('/offline-drafts');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Tingnan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  /// Main Action Card "File a Complaint" (Task 27)
  Widget _buildMainActionCard(BuildContext context, ThemeData theme, String name, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_narrow ? AppTheme.space16 : AppTheme.space32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD61314),
            Color(0xFF991B1B),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD61314).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  'Mabuhay, $name!',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            'Maghain ng Reklamo',
            style: TextStyle(
              fontSize: _narrow ? 22 : 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Ipaabot ang iyong sumbong o alitan sa Lupon Tagapamayapa ng Barangay Rosario sa pamamagitan ng mabilisang step-by-step form.',
            style: TextStyle(
              fontSize: _narrow ? 13 : 14,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          SizedBox(
            width: _narrow ? double.infinity : 240,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FileComplaintScreen()),
                ).then((_) => _checkDrafts());
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: const Text(
                'MAGHAIN NGAYON',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.brand500,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Next Upcoming Hearing Card (Task 27)
  Widget _buildNextHearingCard(ThemeData theme, HearingModel? hearing, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: hearing != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date badge
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.crimsonDarkAccent.withValues(alpha: 0.15) : AppTheme.brand50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppTheme.crimsonDarkAccent.withValues(alpha: 0.3) : AppTheme.brand100,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM').format(hearing.hearingDate).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500,
                        ),
                      ),
                      Text(
                        DateFormat('dd').format(hearing.hearingDate),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'SUSUNOD NA PAGDINIG (HEARING)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: isDark ? AppTheme.textHintDark : AppTheme.textHintLight,
                              ),
                            ),
                          ),
                          StatusBadge(status: hearing.status, compact: true),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        hearing.caseNumber.isNotEmpty ? 'Kaso #${hearing.caseNumber}' : 'Lupon Mediation Hearing',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: isDark ? AppTheme.textHintDark : AppTheme.textHintLight),
                          const SizedBox(width: AppTheme.space4),
                          Text(
                            DateFormat('hh:mm a').format(hearing.hearingDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Icon(Icons.location_on_outlined, size: 14, color: isDark ? AppTheme.textHintDark : AppTheme.textHintLight),
                          const SizedBox(width: AppTheme.space4),
                          Expanded(
                            child: Text(
                              'Barangay Hall Lupon Office',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    size: 24,
                    color: isDark ? AppTheme.textHintDark : AppTheme.textHintLight,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Walang Nakaiskedyul na Pagdinig',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        'Lahat ng iyong kaso ay napakinggan na o naghihintay ng Lupon review.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNoActiveCaseCard(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_narrow ? AppTheme.space16 : AppTheme.space24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 48, color: isDark ? AppTheme.textHintDark : AppTheme.textHintLight),
          const SizedBox(height: AppTheme.space12),
          Text(
            'Walang Aktibong Kaso',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Wala kang patuloy na legal proceeding o pagdinig sa kasalukuyan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(ThemeData theme, ComplaintModel complaint, bool isDark) {
    final isCase = complaint.caseId != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_narrow ? AppTheme.space16 : AppTheme.space24),
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
              Expanded(
                child: Text(
                  isCase ? 'Aktibong Kaso: #${complaint.caseNumber}' : 'Katayuan ng Reklamo: #${complaint.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              StatusBadge(status: complaint.status, compact: true),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          _timelineStep(theme, 'Naihain ang Reklamo', DateFormat('MMM dd, yyyy').format(complaint.dateFiled), true, true, isDark),
          _timelineStep(theme, isCase ? 'Opisyal na Blotter' : 'Sinusuri ng Lupon', isCase ? 'Nagawa ang opisyal na case' : 'Hinihintay ang pagsusuri', isCase, true, isDark),
          _timelineStep(theme, 'Mediation / Paghaharap', 'Status: ${complaint.status}', complaint.status == 'Settled' || complaint.status == 'Closed', true, isDark),
          _timelineStep(theme, 'Resolusyon / Kasunduan', '--', complaint.status == 'Settled' || complaint.status == 'Closed', false, isDark),
        ],
      ),
    );
  }

  Widget _timelineStep(ThemeData theme, String l, String d, bool done, bool line, bool isDark) {
    final color = done
        ? (isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500)
        : (isDark ? AppTheme.textHintDark : AppTheme.textHintLight);

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: color, size: 20),
              if (line) Expanded(child: Container(width: 2, color: color.withValues(alpha: 0.25))),
            ],
          ),
          const SizedBox(width: AppTheme.space12),
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l,
                  style: TextStyle(
                    fontWeight: done ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  d,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(_narrow ? AppTheme.space16 : AppTheme.space24),
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
              const Icon(Icons.emergency_rounded, size: 18, color: AppTheme.brand500),
              const SizedBox(width: AppTheme.space8),
              Text(
                'Emergency Hotlines',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          _contactItem(Icons.local_police_outlined, 'Barangay Rosario Tanod', '0917-889-0123', isDark),
          _contactItem(Icons.local_police_rounded, 'Santiago City PNP', '(078) 305-1234', isDark),
          _contactItem(Icons.local_fire_department_outlined, 'BFP Fire Station', '(078) 305-2222', isDark),
        ],
      ),
    );
  }

  Widget _contactItem(IconData icon, String name, String phone, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: isDark ? AppTheme.textHintDark : AppTheme.textHintLight),
        const SizedBox(width: AppTheme.space8),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ),
        Text(
          phone,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500,
          ),
        ),
      ],
    ),
  );

  Widget _buildProfileCompleteness(ThemeData theme, bool isRegistered, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_narrow ? AppTheme.space16 : AppTheme.space24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRegistered ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
            size: 32,
            color: isRegistered ? AppTheme.success : AppTheme.warning,
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRegistered ? 'Rehistradong Residente' : 'Kailangang Magparehistro',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  isRegistered ? 'Opisyal na nakatala sa Rosario Registry' : 'I-link ang account para makapag-blotter',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
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

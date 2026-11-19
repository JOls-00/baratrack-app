import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/repositories/offline_queue_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../screens/complaints/file_complaint_screen.dart';
import 'admin_offline_home.dart';
import 'admin_pin_dialog.dart';

class OfflineModeScreen extends StatefulWidget {
  const OfflineModeScreen({super.key});

  @override
  State<OfflineModeScreen> createState() => _OfflineModeScreenState();
}

class _OfflineModeScreenState extends State<OfflineModeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _cachedCases = [];
  List<dynamic> _cachedHearings = [];
  bool _isLoading = true;

  final List<Map<String, String>> _emergencyContacts = [
    {
      'title': 'Barangay Rosario Hall Hotline',
      'number': '(078) 305-1234',
      'icon': 'phone',
      'subtitle': 'Desk Officer & Secretariat',
    },
    {
      'title': 'Barangay Tanod Action Center',
      'number': '0917-123-4567',
      'icon': 'security',
      'subtitle': '24/7 Patrol & Community Assistance',
    },
    {
      'title': 'Santiago City Police Station',
      'number': '0998-598-7654',
      'icon': 'local_police',
      'subtitle': 'Emergency: 117 / (078) 305-1177',
    },
    {
      'title': 'BFP Santiago City (Fire Sub-Station)',
      'number': '0915-234-5678',
      'icon': 'fire_truck',
      'subtitle': 'Emergency: 160 / (078) 305-1999',
    },
    {
      'title': 'CDRRMO Disaster & Ambulance Response',
      'number': '0920-987-6543',
      'icon': 'emergency',
      'subtitle': '24/7 Medical & Rescue Team',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    final casesStr = prefs.getString('offline_cached_cases');
    final hearingsStr = prefs.getString('offline_cached_hearings');

    List<dynamic> loadedCases = [];
    List<dynamic> loadedHearings = [];

    if (casesStr != null && casesStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(casesStr);
        if (decoded is List) loadedCases = decoded;
      } catch (_) {}
    }

    if (hearingsStr != null && hearingsStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(hearingsStr);
        if (decoded is List) loadedHearings = decoded;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _cachedCases = loadedCases;
        _cachedHearings = loadedHearings;
        _isLoading = false;
      });
    }
  }

  Future<void> _makeCall(String number) async {
    final cleanNum = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanNum');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final auth = context.watch<AuthProvider>();
    final isFil = context.watch<LocaleProvider>().isFilipino;
    final user = auth.user;
    final isAdminOrStaff = user?.role == 'Admin' || user?.role == 'Staff';

    return Scaffold(
      appBar: AppBar(
        title: const Text('BaraTrack Offline Mode'),
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: isFil ? 'Bumalik sa Online Mode' : 'Back to Online Mode',
          onPressed: () {
            AppRouter.exitOfflineMode();
          },
        ),
        actions: [
          if (isAdminOrStaff)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
              tooltip: 'Admin Offline Portal (PIN Gate)',
              onPressed: () async {
                final unlocked = await AdminPinDialog.show(context);
                if (unlocked == true && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminOfflineHome()),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: isFil ? 'I-reload ang data' : 'Reload cached data',
            onPressed: _loadCachedData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.grey.shade400,
          tabs: [
            Tab(
              icon: const Icon(Icons.folder_shared_outlined, size: 20),
              text: isFil ? 'Mga Kaso (${_cachedCases.length})' : 'Cases (${_cachedCases.length})',
            ),
            Tab(
              icon: const Icon(Icons.event_note_outlined, size: 20),
              text: isFil ? 'Pagdinig (${_cachedHearings.length})' : 'Hearings (${_cachedHearings.length})',
            ),
            const Tab(
              icon: Icon(Icons.contact_phone_outlined, size: 20),
              text: 'Hotlines',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Offline Banner Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.wifi_off_rounded, color: Colors.amber.shade900, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFil ? 'Offline Mode Naka-aktibo' : 'Offline Mode Active',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade900,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        isFil
                            ? 'Ipinapakita ang naka-save na datos habang walang internet signal.'
                            : 'Showing cached records while there is no internet connection.',
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    AppRouter.exitOfflineMode();
                  },
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: Text(isFil ? 'Subukan Online' : 'Try Online', style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: brand),
                ),
              ],
            ),
          ),

          // File Complaint Offline Quick Button
          Builder(
            builder: (ctx) {
              final hasDraft = ctx.watch<OfflineQueueRepository>().draftCount > 0;
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 22),
                  label: Text(
                    hasDraft
                        ? (isFil ? 'Ipagpatuloy ang Naka-save na Draft ng Reklamo' : 'Continue Saved Complaint Draft')
                        : (isFil ? 'Gumawa ng Reklamo (Offline Draft)' : 'Draft a Complaint Offline'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FileComplaintScreen()),
                    );
                    _loadCachedData();
                  },
                ),
              );
            },
          ),

          // Main Tab Views
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: Cached Cases
                      _buildCasesView(isFil),

                      // TAB 2: Cached Hearings
                      _buildHearingsView(isFil),

                      // TAB 3: Emergency Contacts
                      _buildEmergencyContactsView(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasesView(bool isFil) {
    if (_cachedCases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                isFil ? 'Walang Naka-save na Kaso sa Telepono' : 'No Cached Cases on Device',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isFil
                    ? 'Kapag ikaw ay online at binuksan ang iyong mga reklamo, awtomatiko itong mase-save para matingnan mo kahit walang signal.'
                    : 'Once you view your complaints while online, they are automatically cached here for offline viewing.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _cachedCases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _cachedCases[index];
        final complaint = item['complaint'] is Map ? item['complaint'] as Map : null;
        final title = complaint?['type_name'] ??
            item['case_title'] ??
            item['title'] ??
            (isFil ? 'Walang Pamagat' : 'Untitled Case');
        final caseNo = item['case_number'] ?? item['tracking_code'] ?? 'N/A';
        final status = item['status'] ?? 'Pending';
        final date = (item['updated_at'] ?? complaint?['date_filed'] ?? item['created_at'] ?? item['date'] ?? '').toString();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Case #$caseNo',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.brand),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(date, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHearingsView(bool isFil) {
    if (_cachedHearings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                isFil ? 'Walang Naka-save na Iskedyul ng Pagdinig' : 'No Cached Hearing Schedules',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isFil
                    ? 'Awtomatikong magse-save dito ang iyong mga susunod na pagdinig kapag nakakonekta sa internet.'
                    : 'Your upcoming hearing schedules are automatically saved here whenever you are online.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _cachedHearings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _cachedHearings[index];
        final hearingDate = item['hearing_date'] ?? item['scheduled_at'] ?? (isFil ? 'Walang Petsa' : 'No Date');
        final hearingTime = (item['hearing_time'] ?? '').toString();
        final caseNo = (item['case_number'] ?? '').toString();
        final caseTitle = item['case_title'] ??
            (caseNo.isNotEmpty ? 'Case #$caseNo' : (isFil ? 'Pagdinig sa Barangay' : 'Barangay Hearing'));
        final venue = item['venue'] ?? 'Barangay Rosario Hall';
        final dateLine = hearingTime.isNotEmpty ? '$hearingDate · $hearingTime' : '$hearingDate';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: context.brand.withValues(alpha: 0.1),
              child: Icon(Icons.gavel_rounded, color: context.brand),
            ),
            title: Text(caseTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${isFil ? "Petsa" : "Date"}: $dateLine\n${isFil ? "Lugar" : "Venue"}: $venue'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildEmergencyContactsView() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _emergencyContacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final contact = _emergencyContacts[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade50,
              child: Icon(Icons.phone_in_talk_rounded, color: Colors.red.shade700),
            ),
            title: Text(
              contact['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact['subtitle']!, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  contact['number']!,
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.brand, fontSize: 14),
                ),
              ],
            ),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.call, size: 16),
              label: Text(context.read<LocaleProvider>().isFilipino ? 'Tawag' : 'Call'),
              onPressed: () => _makeCall(contact['number']!),
            ),
          ),
        );
      },
    );
  }
}

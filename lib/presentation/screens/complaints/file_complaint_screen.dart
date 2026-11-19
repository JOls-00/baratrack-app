import 'package:dio/dio.dart' show DioException;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart';
import 'location_picker.dart';
import '../../../config/app_theme.dart';
import '../../../data/models/offline_queue_item.dart';
import '../../../data/repositories/offline_queue_repository.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resident_provider.dart';
import '../../providers/evidence_provider.dart';
import '../../providers/locale_provider.dart';
import '../../../data/models/resident_model.dart';
import '../profile/resident_registration_screen.dart';
import 'complaint_submitted_screen.dart';

class FileComplaintScreen extends StatefulWidget {
  final String? draftId;
  const FileComplaintScreen({super.key, this.draftId});

  @override
  State<FileComplaintScreen> createState() => _FileComplaintScreenState();
}

class _FileComplaintScreenState extends State<FileComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0: Who, 1: What, 2: Where, 3: Evidence, 4: Review
  bool _isSubmitting = false;
  String? _currentDraftId;

  // Selection state
  ResidentModel? _selectedRespondent;
  bool _respondentUnknown = false;
  List<PlatformFile> _selectedFiles = [];

  // Controllers & Focus Nodes (Task 33: inline validation on blur and submit)
  final _locationController = TextEditingController();
  final _narrativeController = TextEditingController();
  final _locationFocus = FocusNode();
  final _narrativeFocus = FocusNode();

  String? _respondentError;
  String? _narrativeError;
  String? _locationError;

  LatLng? _incidentPoint;
  bool _addressAutoFilled = false;

  DateTime _incidentDate = DateTime.now();
  TimeOfDay _incidentTime = TimeOfDay.now();
  String _selectedCategory = 'Physical Injury';

  final List<String> _categories = [
    'Physical Injury',
    'Theft/Robbery',
    'Threats',
    'Noise Complaint',
    'Property Damage',
    'Others',
  ];

  int _searchToken = 0;
  bool _hasDraftRestored = false;

  @override
  void initState() {
    super.initState();
    _currentDraftId = widget.draftId;
    _narrativeFocus.addListener(_onNarrativeFocusChanged);
    _locationFocus.addListener(_onLocationFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDraft();
    });
  }

  @override
  void dispose() {
    _narrativeFocus.removeListener(_onNarrativeFocusChanged);
    _locationFocus.removeListener(_onLocationFocusChanged);
    _narrativeFocus.dispose();
    _locationFocus.dispose();
    _locationController.dispose();
    _narrativeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNarrativeFocusChanged() {
    if (!_narrativeFocus.hasFocus) {
      _validateNarrative();
    }
  }

  void _onLocationFocusChanged() {
    if (!_locationFocus.hasFocus) {
      _validateLocation();
    }
  }

  bool _validateNarrative() {
    final text = _narrativeController.text.trim();
    final isFil = context.read<LocaleProvider>().isFilipino;
    if (text.isEmpty) {
      setState(() => _narrativeError = isFil
          ? 'Kailangan ang salaysay: Ipaliwanag ang nangyaring insidente.'
          : 'Narrative required: Please explain what happened.');
      return false;
    } else if (text.length < 10) {
      setState(() => _narrativeError = isFil
          ? 'Masyadong maikli: Maglagay ng hindi bababa sa 10 letra para maunawaan ng Lupon.'
          : 'Too short: Please provide at least 10 characters so the Lupon can review the case.');
      return false;
    } else {
      if (_narrativeError != null) setState(() => _narrativeError = null);
      return true;
    }
  }

  bool _validateLocation() {
    final text = _locationController.text.trim();
    final isFil = context.read<LocaleProvider>().isFilipino;
    if (text.isEmpty) {
      setState(() => _locationError = isFil
          ? 'Kailangan ang lokasyon: Maglagay ng kalye, purok, o palatandaan (hal. "Purok 3, tapat ng kapilya").'
          : 'Location required: Please specify a street, purok, or landmark (e.g. "Purok 3, near chapel").');
      return false;
    } else {
      if (_locationError != null) setState(() => _locationError = null);
      return true;
    }
  }

  bool _validateRespondent() {
    final authProvider = context.read<AuthProvider>();
    final residentId = authProvider.user?.residentId;
    final isFil = context.read<LocaleProvider>().isFilipino;

    if (!_respondentUnknown && _selectedRespondent == null) {
      setState(() => _respondentError = isFil
          ? 'Pumili ng respondent mula sa listahan o lagyan ng tsek ang "Hindi kilala / Unknown".'
          : 'Select a respondent from the list or check "Unknown / Unidentified".');
      return false;
    }
    if (!_respondentUnknown && _selectedRespondent!.id == residentId) {
      setState(() => _respondentError = isFil
          ? 'Hindi mo maaaring ireklamo ang iyong sarili. Pumili ng ibang residente.'
          : 'You cannot file a complaint against yourself. Please select another resident.');
      return false;
    }
    if (_respondentError != null) setState(() => _respondentError = null);
    return true;
  }

  Future<void> _loadDraft() async {
    try {
      final queueRepo = context.read<OfflineQueueRepository>();
      OfflineQueueItem? item;
      if (_currentDraftId != null) {
        item = await queueRepo.getById(_currentDraftId!);
      } else {
        final drafts = await queueRepo.getAll();
        item = drafts.where((d) => d.type == 'complaint' && (d.state == 'draft' || d.state == 'failed')).firstOrNull;
      }

      if (item != null && mounted) {
        final payload = item.payload;
        setState(() {
          _currentDraftId = item!.id;
          _narrativeController.text = payload['narrative']?.toString() ?? '';
          _locationController.text = payload['location']?.toString() ?? '';
          if (_categories.contains(payload['category'])) {
            _selectedCategory = payload['category'].toString();
          }
          if (payload['latitude'] != null && payload['longitude'] != null) {
            _incidentPoint = LatLng(
              (payload['latitude'] as num).toDouble(),
              (payload['longitude'] as num).toDouble(),
            );
          }
          if (payload['incident_date'] != null) {
            final parsedDate = DateTime.tryParse(payload['incident_date'].toString());
            if (parsedDate != null) _incidentDate = parsedDate;
          }
          if (payload['incident_time'] != null) {
            final parts = payload['incident_time'].toString().split(':');
            if (parts.length >= 2) {
              _incidentTime = TimeOfDay(
                hour: int.tryParse(parts[0]) ?? _incidentTime.hour,
                minute: int.tryParse(parts[1]) ?? _incidentTime.minute,
              );
            }
          }
          _respondentUnknown = payload['respondent_unknown'] == true;
          _hasDraftRestored = true;
        });

        if (payload['respondent_id'] != null) {
          try {
            final resList = await context.read<ResidentProvider>().searchRespondents('');
            final found = resList.where((r) => r.id == payload['respondent_id']).firstOrNull;
            if (found != null && mounted) setState(() => _selectedRespondent = found);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[FileComplaintScreen] loadDraft error: $e');
    }
  }

  Future<void> _saveDraft({bool showNotice = true}) async {
    try {
      final queueRepo = context.read<OfflineQueueRepository>();
      final authProvider = context.read<AuthProvider>();
      final payload = {
        'narrative': _narrativeController.text.trim(),
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'incident_date': DateFormat('yyyy-MM-dd').format(_incidentDate),
        'incident_time': '${_incidentTime.hour.toString().padLeft(2, '0')}:${_incidentTime.minute.toString().padLeft(2, '0')}:00',
        'latitude': _incidentPoint?.latitude,
        'longitude': _incidentPoint?.longitude,
        'respondent_id': _selectedRespondent?.id,
        'respondent_unknown': _respondentUnknown,
      };

      final item = OfflineQueueItem(
        id: _currentDraftId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'complaint',
        ownerId: authProvider.user?.id,
        ownerName: authProvider.user?.name,
        payload: payload,
        state: 'draft',
        deviceTime: DateTime.now(),
      );
      await queueRepo.save(item);
      _currentDraftId = item.id;

      if (showNotice && mounted) {
        final hasNarrative = _narrativeController.text.trim().isNotEmpty;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasNarrative
                  ? 'Complaint draft saved offline safely!'
                  : 'Draft saved! Paalala: Lagyan ng salaysay bago ito tuluyang i-submit.',
            ),
            backgroundColor: hasNarrative ? Colors.green : Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[FileComplaintScreen] saveDraft error: $e');
    }
  }

  Future<void> _clearDraft() async {
    try {
      if (_currentDraftId != null) {
        await context.read<OfflineQueueRepository>().delete(_currentDraftId!);
      }
      setState(() => _hasDraftRestored = false);
    } catch (_) {}
  }

  Future<Iterable<ResidentModel>> _searchRespondents(String text, int? currentResidentId) async {
    final query = text.trim();
    if (query.length < 3) return const Iterable<ResidentModel>.empty();
    final token = ++_searchToken;
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || token != _searchToken) return const Iterable<ResidentModel>.empty();
    try {
      final results = await context.read<ResidentProvider>().searchRespondents(query);
      return results.where((r) => r.id != currentResidentId);
    } catch (_) {
      return const Iterable<ResidentModel>.empty();
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp4', 'doc', 'docx'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final newList = List<PlatformFile>.from(_selectedFiles);
      bool exceeded = false;

      for (final file in result.files) {
        final exists = newList.any((f) => f.name == file.name && f.size == file.size);
        if (!exists) {
          if (newList.length < 15) {
            newList.add(file);
          } else {
            exceeded = true;
          }
        }
      }

      if (exceeded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can attach up to 15 files only.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      setState(() {
        _selectedFiles = newList;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _incidentDate) {
      setState(() => _incidentDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _incidentTime,
    );
    if (picked != null && picked != _incidentTime) {
      setState(() => _incidentTime = picked);
    }
  }

  void _goToStep(int step) {
    if (step < 0 || step > 4) return;
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  bool _validateStep(int step) {
    if (step == 0) {
      return _validateRespondent();
    } else if (step == 1) {
      return _validateNarrative();
    } else if (step == 2) {
      return _validateLocation();
    }
    return true;
  }

  void _nextStep() {
    if (_validateStep(_currentStep)) {
      _saveDraft(showNotice: false);
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    _saveDraft(showNotice: false);
    _goToStep(_currentStep - 1);
  }

  Future<void> _submitForm() async {
    final authProvider = context.read<AuthProvider>();
    final residentId = authProvider.user?.residentId;

    // Check resident verification only on Submit
    if (residentId == null) {
      _showRegistrationPrompt();
      return;
    }

    if (!_validateStep(0) || !_validateStep(1) || !_validateStep(2)) {
      return;
    }

    setState(() => _isSubmitting = true);
    final filesToUpload = List<PlatformFile>.from(_selectedFiles);

    try {
      final complaintProvider = context.read<ComplaintProvider>();
      final evidenceProvider = context.read<EvidenceProvider>();
      final String formattedTime = '${_incidentTime.hour.toString().padLeft(2, '0')}:${_incidentTime.minute.toString().padLeft(2, '0')}:00';

      final complaintId = await complaintProvider.submitComplaint(
        complainantId: residentId,
        respondentId: _respondentUnknown ? null : _selectedRespondent!.id,
        category: _selectedCategory,
        location: _locationController.text.trim(),
        latitude: _incidentPoint?.latitude,
        longitude: _incidentPoint?.longitude,
        date: DateFormat('yyyy-MM-dd').format(_incidentDate),
        time: formattedTime,
        details: _narrativeController.text.trim(),
      );

      int uploadedCount = 0;
      final failedFiles = <String>[];

      for (final f in filesToUpload) {
        try {
          await evidenceProvider.uploadEvidence(complaintId: complaintId, file: f);
          uploadedCount++;
        } catch (_) {
          failedFiles.add(f.name);
        }
      }

      await _clearDraft();

      if (mounted) {
        // Navigate to ComplaintSubmittedScreen (Task 32)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintSubmittedScreen(
              complaintId: complaintId,
              category: _selectedCategory,
              respondentName: _respondentUnknown
                  ? 'Hindi kilala / Unknown'
                  : '${_selectedRespondent!.firstName} ${_selectedRespondent!.lastName}',
              location: _locationController.text.trim(),
              incidentDate: DateFormat('MMM dd, yyyy').format(_incidentDate),
              incidentTime: _incidentTime.format(context),
              evidenceCount: uploadedCount,
            ),
          ),
        );
      }
    } catch (e) {
      await _saveDraft(showNotice: false);
      _showError(e is DioException ? 'Connection issue. Your complaint was safely saved as an offline draft!' : 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRegistrationPrompt() {
    final isFil = context.read<LocaleProvider>().isFilipino;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppTheme.brand500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFil ? 'Kailangan ang Resident Profile' : 'Resident Profile Required',
                ),
              ),
            ],
          ),
          content: Text(
            isFil
                ? 'Bago maghain ng reklamo, kailangan mo munang i-setup ang iyong Resident Profile para sa beripikasyon ng Barangay Rosario.'
                : 'Before filing a complaint, please set up your Resident Profile for verification by Barangay Rosario.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isFil ? 'Kanselahin' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResidentRegistrationScreen()),
                );
              },
              child: Text(isFil ? 'I-setup ang Profile' : 'Setup Profile'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFil = context.watch<LocaleProvider>().isFilipino;

    final stepTitles = isFil
        ? ['Sino', 'Ano ang nangyari', 'Saan', 'Ebidensya', 'Pagsusuri']
        : ['Who', 'What happened', 'Where', 'Evidence', 'Review'];
    final stepSubtitles = isFil
        ? [
            'Sino ang sangkot sa insidente?',
            'Ano ang nangyari at kailan?',
            'Saan naganap ang insidente?',
            'Mag-attach ng mga litrato o dokumento (Opsiyonal)',
            'Suriin ang lahat ng detalye bago i-submit',
          ]
        : [
            'Who is involved in the incident?',
            'What happened and when?',
            'Where did the incident occur?',
            'Attach photos or documents (Optional)',
            'Review all details before submitting',
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isFil ? 'Maghain ng Reklamo' : 'File Complaint'),
        actions: [
          TextButton.icon(
            onPressed: () => _saveDraft(showNotice: true),
            icon: const Icon(Icons.bookmark_outline, size: 18),
            label: Text(isFil ? 'I-save ang Draft' : 'Save Draft'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear Progress Indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 5.0,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500,
              ),
              minHeight: 4,
            ),

            // Step Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${_currentStep + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step ${_currentStep + 1} of 5: ${stepTitles[_currentStep]}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stepSubtitles[_currentStep],
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Page View with the 5 Steps
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStepWho(context, isDark, isFil),
                    _buildStepWhat(context, isDark, isFil),
                    _buildStepWhere(context, isDark, isFil),
                    _buildStepEvidence(context, isDark, isFil),
                    _buildStepReview(context, isDark, isFil),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Action Bar
            _buildBottomNav(context, isDark, isFil),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: WHO (SINO)
  // ---------------------------------------------------------------------------
  Widget _buildStepWho(BuildContext context, bool isDark, bool isFil) {
    final authUser = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Complainant Card
          Text(
            isFil ? 'NAGREREKLAMO (COMPLAINANT)' : 'COMPLAINANT',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.brand500.withValues(alpha: 0.12),
                  child: const Icon(Icons.person, color: AppTheme.brand500),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authUser?.name ?? (isFil ? 'Ikaw (You)' : 'You'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        authUser?.residentId != null
                            ? (isFil ? 'Beripikadong Residente (ID: #${authUser!.residentId})' : 'Verified Resident (ID: #${authUser!.residentId})')
                            : (isFil ? 'Nakabinbin ang Resident Profile' : 'Resident profile pending verification'),
                        style: TextStyle(
                          fontSize: 12,
                          color: authUser?.residentId != null ? Colors.green : Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Respondent Section
          Text(
            isFil ? 'INIREREKLAMO (RESPONDENT)' : 'RESPONDENT',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          CheckboxListTile(
            value: _respondentUnknown,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(isFil ? 'Hindi kilala o hindi residente (Unknown / Unidentified)' : 'Unknown / Unidentified person'),
            subtitle: Text(isFil ? 'Lagyan ng tsek kung hindi mo alam ang buong pangalan ng inirereklamo' : 'Check if you do not know the respondent\'s full name'),
            onChanged: (val) {
              setState(() {
                _respondentUnknown = val ?? false;
                if (_respondentUnknown) {
                  _selectedRespondent = null;
                  _respondentError = null;
                }
              });
            },
          ),

          if (_respondentError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.errorBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _respondentError!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!_respondentUnknown) ...[
            const SizedBox(height: 12),
            Autocomplete<ResidentModel>(
              displayStringForOption: (ResidentModel r) => '${r.firstName} ${r.lastName} (${r.zone ?? r.address ?? "Rosario"})',
              optionsBuilder: (TextEditingValue textEditingValue) =>
                  _searchRespondents(textEditingValue.text, authUser?.residentId),
              onSelected: (ResidentModel selection) {
                setState(() {
                  _selectedRespondent = selection;
                  _respondentError = null;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: isFil ? 'Hanapin ang Inirereklamo' : 'Search Respondent',
                    hintText: isFil ? 'I-type ang pangalan (min 3 letra)...' : 'Type name (min 3 letters)...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),

            if (_selectedRespondent != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${isFil ? "Napili" : "Selected"}: ${_selectedRespondent!.firstName} ${_selectedRespondent!.lastName} (${_selectedRespondent!.zone ?? _selectedRespondent!.address ?? "Rosario"})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: isFil ? 'Alisin' : 'Remove',
                      onPressed: () => setState(() => _selectedRespondent = null),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: WHAT HAPPENED (ANO ANG NANGYARI)
  // ---------------------------------------------------------------------------
  Widget _buildStepWhat(BuildContext context, bool isDark, bool isFil) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category
          Text(
            isFil ? 'KATEGORYA NG REKLAMO' : 'COMPLAINT CATEGORY',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),

          const SizedBox(height: 24),

          // Date and Time
          Text(
            isFil ? 'PETSA AT ORAS NG INSIDENTE' : 'DATE & TIME OF INCIDENT',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(DateFormat('MMM dd, yyyy').format(_incidentDate)),
                  onPressed: _selectDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(_incidentTime.format(context)),
                  onPressed: _selectTime,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Narrative
          Text(
            isFil ? 'SALAYSAY NG NANGYARI (NARRATIVE)' : 'INCIDENT NARRATIVE',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _narrativeController,
            focusNode: _narrativeFocus,
            maxLines: 6,
            onChanged: (_) {
              if (_narrativeError != null) _validateNarrative();
            },
            decoration: InputDecoration(
              hintText: isFil
                  ? 'Ipaliwanag nang detalyado kung ano ang nangyari, sino ang mga nakasaksi, at paano nagsimula ang insidente...'
                  : 'Explain in detail what happened, any witnesses present, and how the incident began...',
              helperText: isFil
                  ? 'Maglagay ng sapat na detalye (hindi bababa sa 10 letra).'
                  : 'Provide sufficient details (at least 10 characters).',
              errorText: _narrativeError,
              errorMaxLines: 3,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: WHERE (SAAN)
  // ---------------------------------------------------------------------------
  Widget _buildStepWhere(BuildContext context, bool isDark, bool isFil) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFil ? 'LUGAR O LANDMARK' : 'INCIDENT LOCATION / LANDMARK',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _locationController,
            focusNode: _locationFocus,
            onChanged: (_) {
              if (_locationError != null) _validateLocation();
            },
            decoration: InputDecoration(
              hintText: isFil ? 'e.g. Purok 4, tapat ng Rosario Elementary School' : 'e.g. Purok 4, near Rosario Elementary School',
              helperText: isFil ? 'Ilagay ang kalye, purok, o palatandaan.' : 'Specify street, purok, or landmark.',
              errorText: _locationError,
              errorMaxLines: 2,
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            isFil ? 'PIN THE LOCATION ON MAP (OPSIYONAL)' : 'PIN LOCATION ON MAP (OPTIONAL)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFil
                ? 'I-tap ang mapa para ilipat ang pin. Awtomatikong mapupunan ang address.'
                : 'Tap on the map to place a pin. Address will auto-fill.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          LocationPicker(
            value: _incidentPoint,
            onChanged: (p) => setState(() => _incidentPoint = p),
            onAddress: (a) {
              if (_locationController.text.trim().isEmpty || _addressAutoFilled) {
                setState(() {
                  _locationController.text = a;
                  _addressAutoFilled = true;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: EVIDENCE (EBIDENSYA)
  // ---------------------------------------------------------------------------
  Widget _buildStepEvidence(BuildContext context, bool isDark, bool isFil) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFil ? 'MGA DOKUMENTO AT LARAWAN (OPSIYONAL)' : 'DOCUMENTS & PHOTOS (OPTIONAL)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFil
                ? 'Maaaring mag-attach ng hanggang 15 files (JPG, PNG, PDF, MP4, DOC).'
                : 'You may attach up to 15 files (JPG, PNG, PDF, MP4, DOC).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.attach_file),
            label: Text(
              _selectedFiles.isEmpty
                  ? (isFil ? 'Pumili ng Files' : 'Choose Files')
                  : (isFil ? 'Magdagdag ng Files (${_selectedFiles.length}/15)' : 'Add More Files (${_selectedFiles.length}/15)'),
            ),
            onPressed: _pickFiles,
          ),

          const SizedBox(height: 16),

          if (_selectedFiles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      size: 48,
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFil
                          ? 'Walang kalakip na ebidensya.\nMaaaring magpatuloy nang walang files.'
                          : 'No evidence attached.\nYou may proceed without files.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedFiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                final sizeKb = (file.size / 1024).toStringAsFixed(1);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, color: AppTheme.brand500, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('$sizeKb KB', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedFiles.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 5: REVIEW (PAGSUSURI BAGO I-SUBMIT)
  // ---------------------------------------------------------------------------
  Widget _buildStepReview(BuildContext context, bool isDark, bool isFil) {
    final theme = Theme.of(context);
    final respondentDisplay = _respondentUnknown
        ? (isFil ? 'Hindi kilala / Unknown' : 'Unknown / Unidentified')
        : (_selectedRespondent != null
            ? '${_selectedRespondent!.firstName} ${_selectedRespondent!.lastName}'
            : (isFil ? 'Hindi napili' : 'None selected'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFil ? 'BUOD NG REKLAMO' : 'COMPLAINT SUMMARY',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          _buildReviewCard(
            context,
            isDark,
            isFil,
            title: isFil ? 'Sino ang Sangkot' : 'People Involved',
            stepIndex: 0,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow(isFil ? 'Inirereklamo:' : 'Respondent:', respondentDisplay),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _buildReviewCard(
            context,
            isDark,
            isFil,
            title: isFil ? 'Detalye ng Insidente' : 'Incident Details',
            stepIndex: 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow(isFil ? 'Kategorya:' : 'Category:', _selectedCategory),
                const SizedBox(height: 4),
                _buildReviewRow(
                  isFil ? 'Petsa at Oras:' : 'Date & Time:',
                  isFil
                      ? '${DateFormat('MMM dd, yyyy').format(_incidentDate)} sa ganap na ${_incidentTime.format(context)}'
                      : '${DateFormat('MMM dd, yyyy').format(_incidentDate)} at ${_incidentTime.format(context)}',
                ),
                const SizedBox(height: 6),
                Text(
                  isFil ? 'Salaysay:' : 'Narrative:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  _narrativeController.text.trim().isEmpty
                      ? (isFil ? 'Walang salaysay' : 'No narrative provided')
                      : _narrativeController.text.trim(),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _buildReviewCard(
            context,
            isDark,
            isFil,
            title: isFil ? 'Lugar ng Insidente' : 'Incident Location',
            stepIndex: 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow(isFil ? 'Lugar / Landmark:' : 'Location / Landmark:', _locationController.text.trim()),
                if (_incidentPoint != null) ...[
                  const SizedBox(height: 4),
                  _buildReviewRow('Map Pin:', '${_incidentPoint!.latitude.toStringAsFixed(4)}, ${_incidentPoint!.longitude.toStringAsFixed(4)}'),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          _buildReviewCard(
            context,
            isDark,
            isFil,
            title: isFil ? 'Ebidensya' : 'Evidence',
            stepIndex: 3,
            content: Text(
              _selectedFiles.isEmpty
                  ? (isFil ? 'Walang kalakip na files' : 'No files attached')
                  : (isFil ? '${_selectedFiles.length} file(s) kalakip' : '${_selectedFiles.length} file(s) attached'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.brand500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.brand500.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.brand500, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isFil
                        ? 'Kapag na-submit, opisyal itong itatala sa Barangay Rosario Blotter at bibigyan ng Tracking Number.'
                        : 'Once submitted, this will be officially recorded in the Barangay Rosario Blotter with a Tracking Number.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    BuildContext context,
    bool isDark,
    bool isFil, {
    required String title,
    required int stepIndex,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              InkWell(
                onTap: () => _goToStep(stepIndex),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 14, color: AppTheme.brand500),
                      const SizedBox(width: 4),
                      Text(
                        isFil ? 'I-edit' : 'Edit',
                        style: const TextStyle(fontSize: 12, color: AppTheme.brand500, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAV (BACK & NEXT / SUBMIT BUTTONS)
  // ---------------------------------------------------------------------------
  Widget _buildBottomNav(BuildContext context, bool isDark, bool isFil) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(100, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(isFil ? 'Bumalik' : 'Back'),
              onPressed: _isSubmitting ? null : _previousStep,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _currentStep < 4
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brand500,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Text(
                      isFil ? 'Susunod' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    label: const Icon(Icons.arrow_forward, size: 16),
                    onPressed: _nextStep,
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brand500,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isFil ? 'I-SUBMIT ANG REKLAMO' : 'SUBMIT COMPLAINT',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

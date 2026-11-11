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
    if (text.isEmpty) {
      setState(() => _narrativeError = 'Kailangan ang salaysay: Ipaliwanag ang nangyaring insidente.');
      return false;
    } else if (text.length < 10) {
      setState(() => _narrativeError = 'Masyadong maikli: Maglagay ng hindi bababa sa 10 letra para maunawaan ng Lupon (hal. "Nagkaroon ng pagtatalo sa bakod...").');
      return false;
    } else {
      if (_narrativeError != null) setState(() => _narrativeError = null);
      return true;
    }
  }

  bool _validateLocation() {
    final text = _locationController.text.trim();
    if (text.isEmpty) {
      setState(() => _locationError = 'Kailangan ang lokasyon: Maglagay ng kalye, purok, o palatandaan (hal. "Purok 3, tapat ng kapilya").');
      return false;
    } else {
      if (_locationError != null) setState(() => _locationError = null);
      return true;
    }
  }

  bool _validateRespondent() {
    final authProvider = context.read<AuthProvider>();
    final residentId = authProvider.user?.residentId;

    if (!_respondentUnknown && _selectedRespondent == null) {
      setState(() => _respondentError = 'Pumili ng respondent mula sa listahan o lagyan ng tsek ang "Hindi kilala / Unknown".');
      return false;
    }
    if (!_respondentUnknown && _selectedRespondent!.id == residentId) {
      setState(() => _respondentError = 'Hindi mo maaaring ireklamo ang iyong sarili. Pumili ng ibang residente.');
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppTheme.brand500),
              SizedBox(width: 8),
              Expanded(child: Text('Resident Profile Required')),
            ],
          ),
          content: const Text(
            'Bago maghain ng reklamo, kailangan mo munang i-setup ang iyong Resident Profile para sa beripikasyon ng Barangay Rosario.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Kanselahin'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResidentRegistrationScreen()),
                );
              },
              child: const Text('I-setup ang Profile'),
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

    final stepTitles = ['Who', 'What happened', 'Where', 'Evidence', 'Review'];
    final stepSubtitles = [
      'Sino ang sangkot sa insidente?',
      'Ano ang nangyari at kailan?',
      'Saan naganap ang insidente?',
      'Mag-attach ng mga litrato o dokumento (Opsiyonal)',
      'Suriin ang lahat ng detalye bago i-submit',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Complaint'),
        actions: [
          TextButton.icon(
            onPressed: () => _saveDraft(showNotice: true),
            icon: const Icon(Icons.bookmark_outline, size: 18),
            label: const Text('Save Draft'),
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
                    _buildStepWho(context, isDark),
                    _buildStepWhat(context, isDark),
                    _buildStepWhere(context, isDark),
                    _buildStepEvidence(context, isDark),
                    _buildStepReview(context, isDark),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Action Bar
            _buildBottomNav(context, isDark),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: WHO (SINO)
  // ---------------------------------------------------------------------------
  Widget _buildStepWho(BuildContext context, bool isDark) {
    final authUser = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Complainant Card
          Text(
            'NAGREREKLAMO (COMPLAINANT)',
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
                        authUser?.name ?? 'Ikaw (You)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        authUser?.residentId != null
                            ? 'Verified Resident (ID: #${authUser!.residentId})'
                            : 'Resident profile pending verification',
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
            'INIREREKLAMO (RESPONDENT)',
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
            title: const Text('Hindi kilala o hindi residente (Unknown / Unidentified)'),
            subtitle: const Text('Lagyan ng tsek kung hindi mo alam ang buong pangalan ng inirereklamo'),
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
                    labelText: 'Hanapin ang Inirereklamo',
                    hintText: 'I-type ang pangalan (min 3 letra)...',
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
                        'Napili: ${_selectedRespondent!.firstName} ${_selectedRespondent!.lastName} (${_selectedRespondent!.zone ?? _selectedRespondent!.address ?? "Rosario"})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Alisin',
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
  Widget _buildStepWhat(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category
          Text(
            'KATEGORYA NG REKLAMO',
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
            'PETSA AT ORAS NG INSIDENTE',
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
            'SALAYSAY NG NANGYARI (NARRATIVE)',
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
              hintText: 'Ipaliwanag nang detalyado kung ano ang nangyari, sino ang mga nakasaksi, at paano nagsimula ang insidente...',
              helperText: 'Maglagay ng sapat na detalye (hindi bababa sa 10 letra).',
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
  Widget _buildStepWhere(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LUGAR O LANDMARK',
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
              hintText: 'e.g. Purok 4, tapat ng Rosario Elementary School',
              helperText: 'Ilagay ang kalye, purok, o palatandaan.',
              errorText: _locationError,
              errorMaxLines: 2,
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'PIN THE LOCATION ON MAP (OPSIYONAL)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'I-tap ang mapa para ilipat ang pin. Awtomatikong mapupunan ang address.',
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
  Widget _buildStepEvidence(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MGA DOKUMENTO AT LARAWAN (OPSIYONAL)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Maaaring mag-attach ng hanggang 15 files (JPG, PNG, PDF, MP4, DOC).',
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
            label: Text(_selectedFiles.isEmpty ? 'Pumili ng Files' : 'Magdagdag ng Files (${_selectedFiles.length}/15)'),
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
                      'Walang kalakip na ebidensya.\nMaaaring magpatuloy nang walang files.',
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
  Widget _buildStepReview(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final respondentDisplay = _respondentUnknown
        ? 'Hindi kilala / Unknown'
        : (_selectedRespondent != null
            ? '${_selectedRespondent!.firstName} ${_selectedRespondent!.lastName}'
            : 'Hindi napili');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BUOD NG REKLAMO',
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
            title: 'Sino ang Sangkot',
            stepIndex: 0,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow('Inirereklamo:', respondentDisplay),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _buildReviewCard(
            context,
            isDark,
            title: 'Detalye ng Insidente',
            stepIndex: 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow('Kategorya:', _selectedCategory),
                const SizedBox(height: 4),
                _buildReviewRow('Petsa at Oras:', '${DateFormat('MMM dd, yyyy').format(_incidentDate)} sa ganap na ${_incidentTime.format(context)}'),
                const SizedBox(height: 6),
                Text(
                  'Salaysay:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  _narrativeController.text.trim().isEmpty ? 'Walang salaysay' : _narrativeController.text.trim(),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _buildReviewCard(
            context,
            isDark,
            title: 'Lugar ng Insidente',
            stepIndex: 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow('Lugar / Landmark:', _locationController.text.trim()),
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
            title: 'Ebidensya',
            stepIndex: 3,
            content: Text(
              _selectedFiles.isEmpty ? 'Walang kalakip na files' : '${_selectedFiles.length} file(s) kalakip',
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
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.brand500, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kapag na-submit, opisyal itong itatala sa Barangay Rosario Blotter at bibigyan ng Tracking Number.',
                    style: TextStyle(fontSize: 12),
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
    bool isDark, {
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: AppTheme.brand500),
                      SizedBox(width: 4),
                      Text('I-edit', style: TextStyle(fontSize: 12, color: AppTheme.brand500, fontWeight: FontWeight.w600)),
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
          width: 110,
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
  Widget _buildBottomNav(BuildContext context, bool isDark) {
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
              label: const Text('Bumalik'),
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
                    icon: const Text('Susunod', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                        : const Text(
                            'I-SUBMIT ANG REKLAMO',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

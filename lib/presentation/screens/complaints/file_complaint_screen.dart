import 'package:dio/dio.dart' show DioException;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart';
import 'location_picker.dart';
import '../../../config/app_theme.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/offline_queue_item.dart';
import '../../../data/repositories/offline_queue_repository.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resident_provider.dart';
import '../../providers/evidence_provider.dart';
import '../../../data/models/resident_model.dart';
import '../profile/resident_registration_screen.dart';

class FileComplaintScreen extends StatefulWidget {
  final String? draftId;
  const FileComplaintScreen({super.key, this.draftId});

  @override
  State<FileComplaintScreen> createState() => _FileComplaintScreenState();
}

class _FileComplaintScreenState extends State<FileComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _currentDraftId;
  
  // Selection state
  ResidentModel? _selectedRespondent;
  bool _respondentUnknown = false;
  List<PlatformFile> _selectedFiles = [];
  
  // Controllers
  final _locationController = TextEditingController();
  LatLng? _incidentPoint; // optional map pin
  bool _addressAutoFilled = false; // true while the field still holds the text we filled in
  final _narrativeController = TextEditingController();
  
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

  // Bumped on every keystroke so only the latest respondent search is used.
  int _searchToken = 0;
  bool _hasDraftRestored = false;

  @override
  void initState() {
    super.initState();
    _currentDraftId = widget.draftId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDraft();
    });
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
          _respondentUnknown = payload['respondent_unknown'] == true;
          _hasDraftRestored = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveDraft({bool showNotice = true}) async {
    try {
      final queueRepo = context.read<OfflineQueueRepository>();
      final user = context.read<AuthProvider>().user;

      final copiedPaths = <String>[];
      for (final f in _selectedFiles) {
        if (f.path != null && f.path!.isNotEmpty) {
          final copied = await queueRepo.copyEvidenceToAppDir(f.path!);
          copiedPaths.add(copied);
        }
      }

      final draftId = _currentDraftId ?? queueRepo.newUuid();
      final payload = {
        'title': 'Complaint: $_selectedCategory',
        'category': _selectedCategory,
        'incident_type': _selectedCategory,
        'narrative': _narrativeController.text.trim(),
        'location': _locationController.text.trim(),
        'incident_date': _incidentDate.toIso8601String().split('T')[0],
        'incident_time': '${_incidentTime.hour.toString().padLeft(2, '0')}:${_incidentTime.minute.toString().padLeft(2, '0')}:00',
        'respondent_unknown': _respondentUnknown,
        'respondent_name': _selectedRespondent?.fullName,
        'respondent_id': _selectedRespondent?.id,
        'latitude': _incidentPoint?.latitude,
        'longitude': _incidentPoint?.longitude,
      };

      final draftItem = OfflineQueueItem(
        id: draftId,
        type: 'complaint',
        payload: payload,
        evidencePaths: copiedPaths,
        ownerId: user?.id,
        ownerName: user?.name,
        deviceTime: DateTime.now(),
        state: 'draft',
      );

      await queueRepo.save(draftItem);
      _currentDraftId = draftId;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline draft cleared.')),
        );
      }
    } catch (_) {}
  }

  Future<Iterable<ResidentModel>> _searchRespondents(String text, int? currentResidentId) async {
    final query = text.trim();
    if (query.length < 3) return const Iterable<ResidentModel>.empty();
    final token = ++_searchToken;
    await Future.delayed(const Duration(milliseconds: 350)); // debounce
    if (!mounted || token != _searchToken) return const Iterable<ResidentModel>.empty();
    try {
      final results = await context.read<ResidentProvider>().searchRespondents(query);
      return results.where((r) => r.id != currentResidentId);
    } catch (_) {
      return const Iterable<ResidentModel>.empty();
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _narrativeController.dispose();
    super.dispose();
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

  Future<void> _submitForm() async {
    final authProvider = context.read<AuthProvider>();
    final residentId = authProvider.user?.residentId;

    if (residentId == null) {
      _showRegistrationPrompt();
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (!_respondentUnknown && _selectedRespondent == null) {
        _showError('Please search and select a respondent or mark as unknown.');
        return;
      }

      if (!_respondentUnknown && _selectedRespondent!.id == residentId) {
        _showError('You cannot file a complaint against yourself.');
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
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          
          String message;
          Color color = Colors.green;

          if (filesToUpload.isEmpty) {
            message = 'Complaint filed successfully!';
          } else if (failedFiles.isEmpty) {
            message = 'Complaint filed with $uploadedCount evidence file(s).';
          } else {
            message = 'Complaint filed, but these files could not be uploaded: ${failedFiles.join(', ')}. You can add them from My Complaints.';
            color = Colors.orange[800]!;
          }

          messenger.showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: color,
              duration: const Duration(seconds: 6),
              behavior: SnackBarBehavior.floating,
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
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showRegistrationPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resident Profile Required'),
        content: const Text('You need to complete your official resident profile before you can file a legal complaint.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResidentRegistrationScreen()),
              );
            },
            child: const Text('Complete Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final connectivity = context.watch<ConnectivityProvider>();
    final isOffline = !connectivity.isOnline || AppRouter.userChoseOffline;
    final isOfflineResident = isOffline && (user?.role == 'Resident');

    return Scaffold(
      appBar: AppBar(
        title: const Text('File a New Complaint'),
        backgroundColor: context.brand,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasDraftRestored)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit_note, color: Colors.amber.shade900, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Restored from offline draft',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                            ),
                          ),
                          TextButton(
                            onPressed: _clearDraft,
                            child: const Text('Discard Draft', style: TextStyle(fontSize: 11, color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  _buildSectionHeader('1. Sino ang Kasangkot (Respondent)'),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('Respondent unknown or not identified', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: const Text('Lagyan ng tsek kung hindi pa kilala ang inirereklamo.', style: TextStyle(fontSize: 12)),
                    value: _respondentUnknown,
                    onChanged: (val) {
                      setState(() {
                        _respondentUnknown = val ?? false;
                        if (_respondentUnknown) _selectedRespondent = null;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (!_respondentUnknown) ...[
                    const SizedBox(height: 10),
                    _buildRespondentPicker(user?.residentId),
                  ],
                  const SizedBox(height: 28),
                  _buildSectionHeader('2. Saan at Kailan (Incident Info)'),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;
                      final categoryField = DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Uri ng Reklamo / Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v!),
                      );
                      final locationField = TextFormField(
                        controller: _locationController,
                        onChanged: (_) => _addressAutoFilled = false, // typed by the person: never overwrite it
                        decoration: const InputDecoration(
                          labelText: "Lugar ng Insidente (Location)",
                          hintText: "Purok, Street, Landmark",
                          helperText: 'Awtomatikong napupunan kapag naglagay ng pin.',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (v) => Validators.validateRequired(v, 'Incident Location'),
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            categoryField,
                            const SizedBox(height: 12),
                            locationField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: categoryField),
                          const SizedBox(width: 14),
                          Expanded(child: locationField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Pin the location (opsyonal)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Hindi laging ang kinalalagyan mo ang pinangyarihan. I-tap ang mapa para ilipat ang pin. Hindi mo kailangang ibahagi ang location mo para mag-file.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  LocationPicker(
                    value: _incidentPoint,
                    hidePinMap: isOffline,
                    onChanged: (p) => setState(() => _incidentPoint = p),
                    onAddress: (a) {
                      // Fill the field only if it is empty or still holds our own earlier suggestion.
                      if (_locationController.text.trim().isEmpty || _addressAutoFilled) {
                        setState(() {
                          _locationController.text = a;
                          _addressAutoFilled = true;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).cardTheme.color ?? Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: context.brand),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Petsa / Date', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(_incidentDate),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _selectTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).cardTheme.color ?? Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 18, color: context.brand),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Oras / Time', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _incidentTime.format(context),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader('3. Ano ang Nangyari (Incident Narrative)'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _narrativeController,
                    maxLines: 6,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: "Detalyadong Salaysay (Description)",
                      hintText: "Ipaliwanag nang malinaw ang buong pangyayari...",
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => Validators.validateRequired(v, 'Narrative'),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader('4. Katibayan (Evidence Attachments)'),
                  const SizedBox(height: 12),
                  _buildEvidenceSection(),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isSubmitting || isOfflineResident) ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.brand,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isOfflineResident
                                  ? "Submit when you're back online"
                                  : 'Submit Complaint',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : () => _saveDraft(showNotice: true),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save as Offline Draft', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRespondentPicker(int? currentResidentId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<ResidentModel>(
          displayStringForOption: (option) => option.fullName,
          optionsBuilder: (TextEditingValue textEditingValue) =>
              _searchRespondents(textEditingValue.text, currentResidentId),
          onSelected: (ResidentModel selection) => setState(() => _selectedRespondent = selection),
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Search Resident (Respondent)',
                hintText: 'Type at least 3 letters of the respondent\'s name...',
                prefixIcon: Icon(Icons.search),
              ),
              validator: (v) => (!_respondentUnknown && _selectedRespondent == null) ? 'Selection required' : null,
            );
          },
        ),
        if (_selectedRespondent != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.brand.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.brand.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selected Respondent:', style: TextStyle(fontSize: 12, color: Colors.blueGrey[600])),
                      Text(_selectedRespondent!.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Zone ${_selectedRespondent!.zone ?? 'N/A'}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _selectedRespondent = null),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEvidenceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSoftGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          if (_selectedFiles.isEmpty) ...[
            const Icon(Icons.cloud_upload_outlined, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text('No files selected', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Attach photos, documents or videos (JPG, PNG, PDF, MP4, DOC, DOCX, up to 15 MB each, max 15 files).', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedFiles.length,
              itemBuilder: (context, i) => ListTile(
                leading: Icon(Icons.insert_drive_file, color: context.brand),
                title: Text(_selectedFiles[i].name, style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _selectedFiles.removeAt(i)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.attach_file),
            label: Text(_selectedFiles.isEmpty ? 'Choose Files' : 'Add More Files'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkNavy));
}

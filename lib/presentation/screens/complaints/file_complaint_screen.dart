import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart';
import 'location_picker.dart';
import '../../../config/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resident_provider.dart';
import '../../providers/evidence_provider.dart';
import '../../../data/models/resident_model.dart';
import '../profile/resident_registration_screen.dart';

class FileComplaintScreen extends StatefulWidget {
  const FileComplaintScreen({super.key});

  @override
  State<FileComplaintScreen> createState() => _FileComplaintScreenState();
}

class _FileComplaintScreenState extends State<FileComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  
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
        _showError('Error: ${e.toString()}');
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
    final user = context.watch<AuthProvider>().user;
    final isRegistered = user?.residentId != null;

    if (!isRegistered) {
      return _buildRegistrationRequiredUI();
    }

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
                  _buildSectionHeader('Respondent Selection'),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Respondent unknown or not identified'),
                    subtitle: const Text('Check this if the identity of the person is not yet known.'),
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
                  const SizedBox(height: 16),
                  if (!_respondentUnknown) _buildRespondentPicker(user?.residentId),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Incident Information'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Incident Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          onChanged: (_) => _addressAutoFilled = false, // typed by the person: never overwrite it
                          decoration: const InputDecoration(
                            labelText: "Place of Incident",
                            hintText: "Purok, Street, Landmark",
                            helperText: 'Awtomatikong napupunan kapag naglagay ng pin. Puwede mong baguhin.',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (v) => Validators.validateRequired(v, 'Incident Location'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Pin the location (optional)', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Hindi laging ang kinalalagyan mo ang pinangyarihan. I-tap ang mapa para ilipat ang pin. Hindi mo kailangang ibahagi ang location mo para mag-file.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  LocationPicker(
                    value: _incidentPoint,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Date of Incident'),
                          subtitle: Text(DateFormat('yyyy-MM-dd').format(_incidentDate)),
                          leading: const Icon(Icons.calendar_today),
                          onTap: _selectDate,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ListTile(
                          title: const Text('Time of Incident'),
                          subtitle: Text(_incidentTime.format(context)),
                          leading: const Icon(Icons.access_time),
                          onTap: _selectTime,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Incident Narrative'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _narrativeController,
                    maxLines: 6,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: "Detailed Description",
                      hintText: "Explain what happened in detail...",
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => Validators.validateRequired(v, 'Narrative'),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Evidence Attachments'),
                  const SizedBox(height: 16),
                  _buildEvidenceSection(),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.brand,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Complaint', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildRegistrationRequiredUI() {
    return Scaffold(
      appBar: AppBar(title: const Text('File a New Complaint')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text('Resident Verification Required', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('Your account is not yet linked to the official Barangay Registry. Please complete your resident profile to proceed with legal filings.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResidentRegistrationScreen())), child: const Text('Complete Resident Profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkNavy));
}

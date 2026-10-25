import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/hearing_provider.dart';
import '../../providers/case_provider.dart';
import '../../../data/models/hearing_model.dart';
import '../../../data/models/case_model.dart';

class HearingFormModal extends StatefulWidget {
  final HearingModel? hearing;
  final CaseModel? prefilledCase;
  const HearingFormModal({super.key, this.hearing, this.prefilledCase});

  static void show(BuildContext context, {HearingModel? hearing, CaseModel? prefilledCase}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, // Use root navigator for the bottom sheet
      backgroundColor: Colors.transparent,
      builder: (context) => HearingFormModal(hearing: hearing, prefilledCase: prefilledCase),
    );
  }

  @override
  State<HearingFormModal> createState() => _HearingFormModalState();
}

class _HearingFormModalState extends State<HearingFormModal> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  CaseModel? _selectedCase;
  late String _selectedVenue;
  late String _status;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _venues = ['Barangay Hall', 'Lupon Office', 'Session Hall', 'Mediation Room'];
  final List<String> _statuses = ['Scheduled', 'Completed', 'Postponed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _selectedCase = widget.prefilledCase;
    if (widget.hearing != null) {
      _selectedDate = widget.hearing!.hearingDate;
      final parts = widget.hearing!.hearingTime.split(':');
      _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      _selectedVenue = widget.hearing!.venue;
      _status = widget.hearing!.status;
      _notesController.text = widget.hearing!.notes ?? '';
    } else {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
      _selectedTime = const TimeOfDay(hour: 10, minute: 0);
      _selectedVenue = 'Barangay Hall';
      _status = 'Scheduled';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.hearing == null && _selectedCase == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a case')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    // Use rootNavigator: true for any pop of a dialog/sheet we showed via root navigator
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final provider = context.read<HearingProvider>();
      final String formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      
      final Map<String, dynamic> data = {
        'hearing_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'hearing_time': formattedTime,
        'venue': _selectedVenue,
        'notes': _notesController.text.trim(),
        'status': _status,
      };

      if (widget.hearing != null) {
        await provider.updateHearing(widget.hearing!.id, data);
      } else {
        data['case_id'] = _selectedCase!.id;
        await provider.scheduleHearing(data);
      }

      if (!mounted) return;
      
      // Close loader first
      navigator.pop(); 
      
      // Use microtask to let the first pop transition settle before closing the bottom sheet
      Future.microtask(() {
        if (mounted) {
          navigator.pop(); // Close bottom sheet
          
          messenger.showSnackBar(
            SnackBar(
              content: Text(widget.hearing != null ? 'Hearing updated successfully!' : 'Hearing scheduled successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
      
    } catch (e) {
      if (mounted) {
        navigator.pop(); // Close loader
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.hearing != null;
    final cases = context.watch<CaseProvider>().cases;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Hearing' : 'Schedule New Hearing', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              if (!isEdit && widget.prefilledCase == null) ...[
                const Text('Select Case', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Autocomplete<CaseModel>(
                  displayStringForOption: (c) => 'Case #${c.caseNumber} - ${c.complaint?.typeName ?? "General"}',
                  optionsBuilder: (val) {
                    if (val.text.isEmpty) return const Iterable.empty();
                    return cases.where((c) => c.caseNumber.contains(val.text));
                  },
                  onSelected: (c) => setState(() => _selectedCase = c),
                  fieldViewBuilder: (context, ctrl, focus, onSubmitted) {
                    return TextFormField(
                      controller: ctrl,
                      focusNode: focus,
                      decoration: const InputDecoration(hintText: 'Search case number...', prefixIcon: Icon(Icons.search)),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ] else ...[
                Text('Case #${isEdit ? widget.hearing!.caseNumber : widget.prefilledCase!.caseNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 24),
              ],

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setState(() => _selectedDate = date);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(),
                            child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final time = await showTimePicker(context: context, initialTime: _selectedTime);
                            if (time != null) setState(() => _selectedTime = time);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(),
                            child: Text(_selectedTime.format(context)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Venue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedVenue,
                items: _venues.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _selectedVenue = v!),
              ),
              const SizedBox(height: 24),

              if (isEdit) ...[
                const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _status,
                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 24),
              ],

              const Text('Notes / Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Any specific instructions for the parties...'),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(isEdit ? 'Update Schedule' : 'Schedule Hearing'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

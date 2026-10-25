import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/resident_model.dart';
import '../../providers/resident_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../config/app_theme.dart';

class ResidentFormScreen extends StatefulWidget {
  final ResidentModel? resident;
  const ResidentFormScreen({super.key, this.resident});

  @override
  State<ResidentFormScreen> createState() => _ResidentFormScreenState();
}

class _ResidentFormScreenState extends State<ResidentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _gender = 'Male';
  String _zone = '1';
  String _status = 'Active';
  DateTime? _birthDate;
  int? _userId;

  @override
  void initState() {
    super.initState();
    if (widget.resident != null) {
      final r = widget.resident!;
      _firstNameController.text = r.firstName;
      _lastNameController.text = r.lastName;
      _middleNameController.text = r.middleName;
      _contactController.text = r.contact ?? '';
      _emailController.text = r.email ?? '';
      _addressController.text = r.address ?? '';
      _gender = r.gender ?? 'Male';
      _zone = r.zone ?? '1';
      _status = r.status;
      _birthDate = r.birthDate;
      _userId = r.userId;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _birthDate != null) {
      setState(() => _isLoading = true);
      try {
        final provider = context.read<ResidentProvider>();
        
        final Map<String, dynamic> data = {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'middle_name': _middleNameController.text.trim(),
          'gender': _gender,
          'birth_date': DateFormat('yyyy-MM-dd').format(_birthDate!),
          'contact': _contactController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'zone': _zone,
          'status': _status,
          'user_id': _userId, // Include user_id if linked
        };

        if (widget.resident != null) {
          await provider.updateResident(widget.resident!.id, data);
        } else {
          await provider.createResident(data);
        }

        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context, true);
          messenger.showSnackBar(
            SnackBar(
              content: Text(widget.resident != null ? 'Resident updated!' : 'Resident registered!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a birth date')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.resident != null;
    
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Resident' : 'Register Resident')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (v) => Validators.validateRequired(v, 'First Name'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (v) => Validators.validateRequired(v, 'Last Name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _middleNameController,
                decoration: const InputDecoration(labelText: 'Middle Name (Optional)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _birthDate ?? DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _birthDate = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Birth Date'),
                        child: Text(_birthDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_birthDate!)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(labelText: 'Contact Number'),
                      validator: (v) => Validators.validateRequired(v, 'Contact'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _zone,
                      decoration: const InputDecoration(labelText: 'Zone / Purok'),
                      items: ['1', '2', '3', '4', '5', '6', '7'].map((z) => DropdownMenuItem(value: z, child: Text('Zone $z'))).toList(),
                      onChanged: (v) => setState(() => _zone = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address (Optional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Detailed Address'),
                validator: (v) => Validators.validateRequired(v, 'Address'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Active', 'Deceased', 'Relocated'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isEdit ? 'Save Changes' : 'Register Resident'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

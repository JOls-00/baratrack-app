import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../../data/repositories/resident_repository.dart';

class ResidentRegistrationScreen extends StatefulWidget {
  const ResidentRegistrationScreen({super.key});

  @override
  State<ResidentRegistrationScreen> createState() => _ResidentRegistrationScreenState();
}

class _ResidentRegistrationScreenState extends State<ResidentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _gender = 'Male';
  String _zone = '1';
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final names = user.name.split(' ');
      if (names.isNotEmpty) _firstNameController.text = names[0];
      if (names.length > 1) _lastNameController.text = names.sublist(1).join(' ');
      _contactController.text = user.contactNumber ?? '';
      _addressController.text = user.address ?? '';
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _birthDate != null) {
      setState(() => _isLoading = true);
      try {
        final auth = context.read<AuthProvider>();
        final residentRepo = context.read<ResidentRepository>();
        
        final residentId = await residentRepo.createResident({
          'user_id': auth.user!.id,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'middle_name': _middleNameController.text.trim(),
          'gender': _gender,
          'birth_date': DateFormat('yyyy-MM-dd').format(_birthDate!),
          'contact': _contactController.text.trim(),
          'address': _addressController.text.trim(),
          'zone': _zone,
          'status': 'Active',
        });

        await auth.setResidentId(residentId);
        
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          messenger.showSnackBar(
            const SnackBar(content: Text('Resident registration complete!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your birth date')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Resident Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Legal Verification Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                'To file complaints or request documents, you must link your account to the official Barangay Resident Registry.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
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
                          initialDate: DateTime(2000),
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
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Detailed Address'),
                validator: (v) => Validators.validateRequired(v, 'Address'),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Complete Registration'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

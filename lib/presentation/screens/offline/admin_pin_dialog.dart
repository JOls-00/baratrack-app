import 'package:flutter/material.dart';
import '../../../core/security/offline_pin_service.dart';

class AdminPinDialog extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AdminPinDialog({super.key, required this.onAuthenticated});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdminPinDialog(
        onAuthenticated: () => Navigator.pop(ctx, true),
      ),
    );
  }

  @override
  State<AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<AdminPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _hasError = false;
  String _errorMessage = '';
  bool _isChecking = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() {
        _hasError = true;
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }

    setState(() => _isChecking = true);
    final valid = await OfflinePinService.verifyPin(pin);
    if (!mounted) return;

    if (valid) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _isChecking = false;
        _hasError = true;
        _errorMessage = 'Incorrect PIN. Try again or check default (1234).';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, color: Color(0xFFD61314), size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Admin Offline Gate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Gate: Offline access for Barangay Staff requires your 4+ digit security PIN.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 8,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Security PIN',
              hintText: 'Enter 4+ digits',
              errorText: _hasError ? _errorMessage : null,
              prefixIcon: const Icon(Icons.pin),
            ),
            onSubmitted: (_) => _verify(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD61314),
            foregroundColor: Colors.white,
          ),
          onPressed: _isChecking ? null : _verify,
          child: _isChecking
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Unlock Admin'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

enum ConflictChoice { keepMine, useServer }

class ConflictDialog extends StatelessWidget {
  final String title;
  final String localValue;
  final String serverValue;
  final String serverUpdatedAt;

  const ConflictDialog({
    super.key,
    required this.title,
    required this.localValue,
    required this.serverValue,
    required this.serverUpdatedAt,
  });

  static Future<ConflictChoice?> show(
    BuildContext context, {
    required String title,
    required String localValue,
    required String serverValue,
    required String serverUpdatedAt,
  }) {
    return showDialog<ConflictChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConflictDialog(
        title: title,
        localValue: localValue,
        serverValue: serverValue,
        serverUpdatedAt: serverUpdatedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.merge_type_rounded, color: Colors.deepOrange, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Conflict Detected: $title',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This case was updated on the server while you were offline. Choose which version to keep:',
              style: TextStyle(fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR OFFLINE VERSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                  const SizedBox(height: 4),
                  Text(localValue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SERVER VERSION (As of $serverUpdatedAt)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                  const SizedBox(height: 4),
                  Text(serverValue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, ConflictChoice.useServer),
          child: const Text('Use Server Version'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD61314), foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, ConflictChoice.keepMine),
          child: const Text('Keep My Change'),
        ),
      ],
    );
  }
}

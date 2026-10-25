import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/branding_repository.dart';
import '../../providers/branding_provider.dart';
import '../portal/landing_sections.dart';

/// Admin-only card in Settings: add, edit and remove the officials shown on the public portal.
class OfficialsCard extends StatelessWidget {
  const OfficialsCard({super.key});

  static const groups = <String, String>{
    'captain': 'Punong Barangay',
    'council': 'Sangguniang Barangay (Kagawad)',
    'sk': 'Sangguniang Kabataan',
    'staff': 'Barangay Staff',
  };

  Future<void> _edit(BuildContext context, [Official? official]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BrandingProvider>(),
        child: _OfficialDialog(official: official),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Official o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove official?'),
        content: Text('${o.name} will no longer appear on the public portal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<BrandingProvider>().deleteOfficial(o.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final officials = context.watch<BrandingProvider>().officials;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Shown on the public portal under "Barangay Officials".',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Add official'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (officials.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No officials yet. Start with the Punong Barangay.'),
              )
            else
              for (final o in officials)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: OfficialAvatar(official: o, size: 44),
                  title: Text(o.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${o.position} · ${groups[o.group] ?? o.group}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(context, o),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(context, o),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _OfficialDialog extends StatefulWidget {
  final Official? official;
  const _OfficialDialog({this.official});

  @override
  State<_OfficialDialog> createState() => _OfficialDialogState();
}

class _OfficialDialogState extends State<_OfficialDialog> {
  late final TextEditingController _name;
  late final TextEditingController _position;
  late final TextEditingController _order;
  late String _group;
  PlatformFile? _photo;
  bool _removePhoto = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final o = widget.official;
    _name = TextEditingController(text: o?.name ?? '');
    _position = TextEditingController(text: o?.position ?? '');
    _order = TextEditingController(text: '${o?.sortOrder ?? 0}');
    _group = o?.group ?? 'council';
  }

  @override
  void dispose() {
    _name.dispose();
    _position.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() {
        _photo = result.files.first;
        _removePhoto = false;
      });
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _position.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the name and position.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<BrandingProvider>().saveOfficial(
            id: widget.official?.id,
            name: _name.text.trim(),
            position: _position.text.trim(),
            group: _group,
            sortOrder: int.tryParse(_order.text.trim()) ?? 0,
            photo: _photo,
            removePhoto: _removePhoto,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.official;
    final hasExisting = o != null && o.hasPhoto && !_removePhoto && _photo == null;
    return AlertDialog(
      title: Text(o == null ? 'Add official' : 'Edit official'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _photo?.bytes != null
                        ? MemoryImage(_photo!.bytes!)
                        : (hasExisting ? NetworkImage(o!.photoUrl) : null) as ImageProvider?,
                    child: (_photo == null && !hasExisting) ? const Icon(Icons.person, size: 34) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickPhoto,
                          icon: const Icon(Icons.photo_camera_outlined, size: 18),
                          label: const Text('Photo'),
                        ),
                        if (o != null && o.hasPhoto || _photo != null)
                          TextButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() {
                                      _photo = null;
                                      _removePhoto = true;
                                    }),
                            child: const Text('Remove photo'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 12),
              TextField(
                controller: _position,
                decoration: const InputDecoration(labelText: 'Position', hintText: 'e.g. Punong Barangay, Kagawad'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _group,
                decoration: const InputDecoration(labelText: 'Group'),
                items: [
                  for (final e in OfficialsCard.groups.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _group = v ?? 'council'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _order,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Display order (0 = first)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}

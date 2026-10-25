import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../providers/branding_provider.dart';

/// Admin-only card in Settings: barangay name, logo, theme colour, About and Contact details.
class BrandingCard extends StatefulWidget {
  const BrandingCard({super.key});

  @override
  State<BrandingCard> createState() => _BrandingCardState();
}

class _BrandingCardState extends State<BrandingCard> {
  static const _presets = <(String, String)>[
    ('Rosario Red', '#D61314'),
    ('Maroon', '#7F1D1D'),
    ('Orange', '#C2410C'),
    ('Forest Green', '#15803D'),
    ('Teal', '#0F766E'),
    ('Royal Blue', '#1D4ED8'),
    ('Navy', '#1E3A8A'),
    ('Purple', '#7E22CE'),
  ];

  late final Map<String, TextEditingController> _c;
  PlatformFile? _picked;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = context.read<BrandingProvider>().info;
    _c = {
      'barangay_name': TextEditingController(text: i.name),
      'city_name': TextEditingController(text: i.city),
      'primary_color': TextEditingController(text: i.primaryHex),
      'slogan': TextEditingController(text: i.slogan),
      'about_text': TextEditingController(text: i.about),
      'history': TextEditingController(text: i.history),
      'album': TextEditingController(text: i.album),
      'mission': TextEditingController(text: i.mission),
      'vision': TextEditingController(text: i.vision),
      'address': TextEditingController(text: i.address),
      'contact_phone': TextEditingController(text: i.phone),
      'contact_email': TextEditingController(text: i.email),
      'office_hours': TextEditingController(text: i.officeHours),
    };
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Color _previewColor() {
    final h = _c['primary_color']!.text.trim().replaceAll('#', '');
    final v = int.tryParse(h.length == 6 ? 'FF$h' : '', radix: 16);
    return v == null ? Colors.grey : Color(v);
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() => _picked = result.files.first);
    }
  }

  Future<void> _save() async {
    if (_c['barangay_name']!.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the barangay name.')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<BrandingProvider>().save(
            {for (final e in _c.entries) e.key: e.value.text.trim()},
            logo: _picked,
          );
      if (!mounted) return;
      setState(() {
        _picked = null;
        _saving = false;
      });
      messenger.showSnackBar(const SnackBar(content: Text('Saved. The portal now shows your changes.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red[700],
      ));
    }
  }

  Widget _field(String key, String label, {int lines = 1, int? max}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: _c[key],
          minLines: lines,
          maxLines: lines,
          maxLength: max,
          decoration: InputDecoration(labelText: label, alignLabelWithHint: lines > 1),
        ),
      );

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Everything here appears on the public portal, the login page and the sidebar.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            _heading('Logo & name'),
            Wrap(
              spacing: 28,
              runSpacing: 20,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: _picked?.bytes != null
                            ? Image.memory(_picked!.bytes!, fit: BoxFit.contain)
                            : const BrandLogo(size: 92),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pick,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Choose logo'),
                    ),
                    const SizedBox(height: 4),
                    Text('PNG, JPG or WEBP, up to 2 MB', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420, minWidth: 260),
                  child: Column(children: [
                    _field('barangay_name', 'Barangay name'),
                    _field('city_name', 'City / Municipality'),
                  ]),
                ),
              ],
            ),

            _heading('Theme color'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final p in _presets)
                  Tooltip(
                    message: p.$1,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _c['primary_color']!.text = p.$2),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(int.parse('FF${p.$2.substring(1)}', radix: 16)),
                          border: Border.all(
                            color: _c['primary_color']!.text.toUpperCase() == p.$2 ? Colors.black87 : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _c['primary_color'],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Hex code',
                      hintText: '#D61314',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircleAvatar(radius: 8, backgroundColor: _previewColor()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Buttons, links, banner and highlights follow this color.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),

            const SizedBox(height: 20),
            _heading('About the barangay'),
            _field('slogan', 'Official slogan (home page and footer)', max: 160),
            _field('about_text', 'About (short intro on the home page)', lines: 4, max: 2000),
            _field('history', 'Brief history of the barangay', lines: 8, max: 6000),
            _field('album', 'Album photo links (one https link per line)', lines: 5, max: 6000),
            _field('mission', 'Mission', lines: 2, max: 800),
            _field('vision', 'Vision', lines: 2, max: 800),

            _heading('Contact details'),
            _field('address', 'Barangay hall address'),
            _field('contact_phone', 'Phone / mobile'),
            _field('contact_email', 'Email'),
            _field('office_hours', 'Office hours (e.g. Mon-Fri, 8:00 AM - 5:00 PM)'),

            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

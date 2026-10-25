import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/content_repository.dart';

/// Admin-only card in Settings: add, edit, hide or remove the FAQs shown on the
/// public portal and used by the chat helper.
class FaqManagerCard extends StatefulWidget {
  const FaqManagerCard({super.key});

  @override
  State<FaqManagerCard> createState() => _FaqManagerCardState();
}

class _FaqManagerCardState extends State<FaqManagerCard> {
  List<AdminFaq> _faqs = [];
  bool _loading = true;
  String? _error;

  ContentRepository get _repo => context.read<ContentRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final faqs = await _repo.fetchFaqs();
      if (mounted) setState(() => _faqs = faqs);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([AdminFaq? faq]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _FaqDialog(
        faq: faq,
        repository: _repo,
        categories: _faqs.map((f) => f.category).toSet().toList(),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(AdminFaq faq) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete FAQ?'),
        content: Text('"${faq.question}" will be removed from the portal and the chat helper.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.deleteFaq(faq.id);
      _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, List<AdminFaq>>{};
    for (final f in _faqs) {
      byCategory.putIfAbsent(f.category, () => []).add(f);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Shown on the public portal under "FAQ" and used by the chat helper.',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add FAQ'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_faqs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No FAQs yet. Tap "Add FAQ" to write the first one.'),
              )
            else
              for (final entry in byCategory.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(entry.key.toUpperCase(),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Theme.of(context).colorScheme.primary)),
                ),
                for (final f in entry.value)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(f.question, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      f.isActive ? f.answer : 'Hidden · ${f.answer}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: f.isActive ? null : Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(f),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(f),
                        ),
                      ],
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

class _FaqDialog extends StatefulWidget {
  final AdminFaq? faq;
  final ContentRepository repository;
  final List<String> categories;
  const _FaqDialog({this.faq, required this.repository, required this.categories});

  @override
  State<_FaqDialog> createState() => _FaqDialogState();
}

class _FaqDialogState extends State<_FaqDialog> {
  late final TextEditingController _category;
  late final TextEditingController _question;
  late final TextEditingController _answer;
  late final TextEditingController _order;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final f = widget.faq;
    _category = TextEditingController(text: f?.category ?? '');
    _question = TextEditingController(text: f?.question ?? '');
    _answer = TextEditingController(text: f?.answer ?? '');
    _order = TextEditingController(text: '${f?.sortOrder ?? 0}');
    _active = f?.isActive ?? true;
  }

  @override
  void dispose() {
    _category.dispose();
    _question.dispose();
    _answer.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final category = _category.text.trim();
    final question = _question.text.trim();
    final answer = _answer.text.trim();
    final order = int.tryParse(_order.text.trim());
    if (category.isEmpty || question.isEmpty || answer.isEmpty) {
      setState(() => _error = 'Please fill in the category, question and answer.');
      return;
    }
    if (order == null || order < 0 || order > 999) {
      setState(() => _error = 'Order must be a number from 0 to 999.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveFaq(
        id: widget.faq?.id,
        category: category,
        question: question,
        answer: answer,
        sortOrder: order,
        isActive: _active,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.faq != null;
    return AlertDialog(
      title: Text(editing ? 'Edit FAQ' : 'Add FAQ'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _category,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Category',
                  helperText: widget.categories.isEmpty
                      ? 'FAQs with the same category are grouped together.'
                      : 'Existing: ${widget.categories.join(', ')}',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _question,
                maxLength: 255,
                decoration: const InputDecoration(labelText: 'Question'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _answer,
                minLines: 3,
                maxLines: 8,
                maxLength: 5000,
                decoration: const InputDecoration(labelText: 'Answer', alignLabelWithHint: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _order,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Order within category (0 = first)'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show on the portal'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
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

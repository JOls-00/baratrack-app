import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AnnouncementProvider>().load();
    });
  }

  Future<void> _edit([AnnouncementModel? announcement]) {
    return showDialog<void>(
      context: context,
      builder: (_) => _AnnouncementDialog(
        announcement: announcement,
        provider: context.read<AnnouncementProvider>(),
      ),
    );
  }

  Future<void> _delete(AnnouncementModel a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: Text('"${a.title}" will be removed for everyone, including the public portal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AnnouncementProvider>().delete(a.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AnnouncementProvider>();
    final role = context.watch<AuthProvider>().user?.role;
    final canEdit = role == 'Admin' || role == 'Staff';
    final announcements = provider.announcements;

    Widget body;
    if (provider.isLoading && announcements.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (announcements.isEmpty) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(child: Icon(Icons.campaign_outlined, size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.5))),
          const SizedBox(height: 12),
          Center(
            child: Text(
              provider.error ?? (canEdit ? 'No announcements yet. Tap "New announcement" to post one.' : 'No announcements yet.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      );
    } else {
      body = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final a = announcements[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DateFormat('MMMM dd, yyyy').format(a.date),
                          style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      if (canEdit)
                        PopupMenuButton<String>(
                          tooltip: 'Options',
                          onSelected: (v) => v == 'edit' ? _edit(a) : _delete(a),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(a.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  Text(a.content, style: const TextStyle(fontSize: 16, height: 1.6)),
                ],
              ),
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Announcements', style: theme.textTheme.headlineLarge),
                    const Text('Official updates and alerts from the Barangay Council.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              if (canEdit)
                ElevatedButton.icon(
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New announcement'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<AnnouncementProvider>().load(),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementDialog extends StatefulWidget {
  final AnnouncementModel? announcement;
  final AnnouncementProvider provider;
  const _AnnouncementDialog({this.announcement, required this.provider});

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.announcement?.title ?? '');
    _body = TextEditingController(text: widget.announcement?.content ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(() => _error = 'Please enter both a title and the message.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.provider.save(id: widget.announcement?.id, title: title, body: body);
      if (mounted) Navigator.pop(context);
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
    final editing = widget.announcement != null;
    return AlertDialog(
      title: Text(editing ? 'Edit announcement' : 'New announcement'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _body,
                minLines: 4,
                maxLines: 8,
                maxLength: 5000,
                decoration: const InputDecoration(labelText: 'Message', alignLabelWithHint: true),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
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
              : Text(editing ? 'Save' : 'Post'),
        ),
      ],
    );
  }
}

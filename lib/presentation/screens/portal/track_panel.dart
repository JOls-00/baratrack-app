import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../data/repositories/portal_repository.dart';
import '../../providers/portal_provider.dart';
import 'landing_sections.dart';

class TrackPanel extends StatefulWidget {
  const TrackPanel();

  @override
  State<TrackPanel> createState() => TrackPanelState();
}

class TrackPanelState extends State<TrackPanel> {
  final _refController = TextEditingController();
  final _lastController = TextEditingController();
  bool _busy = false;
  String? _error;
  TrackResult? _result;

  @override
  void dispose() {
    _refController.dispose();
    _lastController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ref = _refController.text.trim();
    final last = _lastController.text.trim();
    if (ref.isEmpty || last.isEmpty) {
      setState(() => _error = 'Please enter the reference number and last name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await context.read<PortalProvider>().track(ref, last);
      if (!mounted) return;
      setState(() {
        _result = r;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = brandPrimary(context);
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.travel_explore, color: primary),
              const SizedBox(width: 10),
              Text('Track your application',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 4),
            Text('No account needed. Enter the reference number you received.',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final refField = TextField(
                controller: _refController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Reference # (CMP-… or CASE-…)',
                  prefixIcon: Icon(Icons.tag),
                ),
                onSubmitted: (_) => _submit(),
              );
              final lastField = TextField(
                controller: _lastController,
                decoration: const InputDecoration(labelText: 'Last name', prefixIcon: Icon(Icons.person_outline)),
                onSubmitted: (_) => _submit(),
              );
              final button = SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Track', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
              if (c.maxWidth > 640) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 13, child: refField),
                    const SizedBox(width: 10),
                    Expanded(flex: 10, child: lastField),
                    const SizedBox(width: 10),
                    button,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [refField, const SizedBox(height: 10), lastField, const SizedBox(height: 10), button],
              );
            }),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade800))),
                  ],
                ),
              ),
            ],
            if (_result != null) _buildResult(_result!, primary),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(TrackResult r, Color primary) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(r.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.burstOrange.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(r.headline,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8A5200))),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(r.reference, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 16),
          for (var i = 0; i < r.steps.length; i++) _stepRow(r.steps[i], primary, isLast: i == r.steps.length - 1),
        ],
      ),
    );
  }

  Widget _stepRow(TrackStep s, Color primary, {required bool isLast}) {
    final done = s.state == 'done';
    final current = s.state == 'current';
    final dot = Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? primary : Colors.white,
        border: Border.all(color: (done || current) ? primary : Colors.grey.shade400, width: 2),
        boxShadow: current ? [BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 0, spreadRadius: 4)] : null,
      ),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Padding(padding: const EdgeInsets.only(top: 3), child: dot),
                if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.label,
                    style: TextStyle(
                      fontWeight: (done || current) ? FontWeight.w600 : FontWeight.normal,
                      color: s.state == 'todo' ? Colors.grey.shade600 : null,
                    ),
                  ),
                  if (s.detail.isNotEmpty) Text(s.detail, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


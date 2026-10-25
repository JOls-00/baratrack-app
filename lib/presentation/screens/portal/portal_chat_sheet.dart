import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../providers/branding_provider.dart';
import '../../providers/portal_provider.dart';
import 'portal_greeting.dart';

/// Opens the help assistant as a bottom sheet.
Future<void> showPortalChat(BuildContext context, {String page = 'home'}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _ChatSheet(page: page),
  );
}

class _Msg {
  final bool mine;
  final String text;
  const _Msg(this.mine, this.text);
}

class _ChatSheet extends StatefulWidget {
  final String page;
  const _ChatSheet({required this.page});

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  late final String _greeting;
  late final List<String> _suggestions;
  final _messages = <_Msg>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final name = context.read<BrandingProvider>().info.name;
    _greeting = PortalGreeting.opening(name, widget.page);
    _suggestions = PortalGreeting.suggestions(widget.page);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    setState(() {
      _messages.add(_Msg(true, text));
      _busy = true;
    });
    _scrollDown();

    final history = _messages
        .map((m) => {'role': m.mine ? 'user' : 'assistant', 'content': m.text})
        .toList();
    final start = history.length > 8 ? history.length - 8 : 0;
    final reply = await context.read<PortalProvider>().askAssistant(history.sublist(start));
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(false, reply));
      _busy = false;
    });
    _scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              decoration: BoxDecoration(
                color: context.brand,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent, color: Colors.white),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('BaraTrack Assistant',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(14),
                children: [
                  _bubble(_Msg(false, _greeting)),
                  for (final m in _messages) _bubble(m),
                  if (_busy) _bubble(const _Msg(false, '…')),
                ],
              ),
            ),
            if (_messages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final s in _suggestions)
                      ActionChip(label: Text(s, style: const TextStyle(fontSize: 12)), onPressed: () => _send(s)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Type your question...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: context.brand),
                    onPressed: _busy ? null : () => _send(),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                'Automated assistant. For official matters, confirm with the barangay office.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_Msg m) {
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: m.mine ? context.brand : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          m.text,
          style: TextStyle(color: m.mine ? Colors.white : Colors.black87, height: 1.35),
        ),
      ),
    );
  }
}

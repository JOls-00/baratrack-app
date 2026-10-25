import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/portal_repository.dart';
import '../../providers/portal_provider.dart';
import 'landing_sections.dart';
import 'portal_shell.dart';

/// Public FAQs page: search + categories + expandable answers.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _search = TextEditingController();
  int _category = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalProvider>();
    final primary = brandPrimary(context);
    final faqs = portal.faqs;
    final query = _search.text.trim().toLowerCase();
    if (_category >= faqs.length) _category = 0;

    List<FaqItem> items = [];
    if (faqs.isNotEmpty) {
      items = query.isEmpty
          ? faqs[_category].items
          : faqs
              .expand((c) => c.items)
              .where((i) => '${i.question} ${i.answer}'.toLowerCase().contains(query))
              .toList();
    }

    return PortalShell(
      current: 'faqs',
      child: SectionFrame(
        title: 'Frequently Asked Questions',
        subtitle: 'Narito ang mga sagot sa pinakakaraniwang tanong tungkol sa pagsusumite at pag-track ng reklamo, account security, at privacy.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search FAQs — halimbawa: OTP, hearing, reklamo',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (portal.isLoading && faqs.isEmpty)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (faqs.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Text('No FAQs available yet.'))
            else ...[
              if (query.isEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < faqs.length; i++)
                      ChoiceChip(
                        label: Text(faqs[i].name),
                        selected: i == _category,
                        selectedColor: primary.withValues(alpha: 0.15),
                        onSelected: (_) => setState(() => _category = i),
                      ),
                  ],
                )
              else
                Text('Search results', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Text('Walang nahanap. Subukan ang ibang salita.'))
              else
                for (final item in items)
                  Card(
                    child: ExpansionTile(
                      title: Text(item.question, style: const TextStyle(fontWeight: FontWeight.w600)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(item.answer, style: TextStyle(color: Colors.grey.shade700, height: 1.4))],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/case_provider.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/list_skeleton_placeholder.dart';

class CaseListScreen extends StatefulWidget {
  final String? statusFilter;
  const CaseListScreen({super.key, this.statusFilter});

  @override
  State<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends State<CaseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().fetchCases(status: widget.statusFilter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final caseProvider = context.watch<CaseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.statusFilter != null ? '${widget.statusFilter} Cases' : 'Cases & Blotter'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by case number or name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onChanged: (value) => caseProvider.fetchCases(query: value, status: widget.statusFilter),
            ),
          ),
        ),
      ),
      body: caseProvider.isLoading && caseProvider.cases.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: ListSkeletonPlaceholder(itemCount: 5),
            )
          : RefreshIndicator(
              onRefresh: () => caseProvider.fetchCases(status: widget.statusFilter),
              child: caseProvider.cases.isEmpty
                  ? EmptyStateView(
                      icon: Icons.folder_open_rounded,
                      title: 'Walang nahanap na mga kaso',
                      message: widget.statusFilter != null
                          ? 'Walang kaso sa ilalim ng katayuang "${widget.statusFilter}".'
                          : 'Walang opisyal na blotter record na tumutugma sa iyong paghahanap.',
                    )
                  : ListView.builder(
                      itemCount: caseProvider.cases.length,
                      itemBuilder: (context, index) {
                        final item = caseProvider.cases[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(item.caseNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(item.complaint?.details ?? 'No details provided'),
                            trailing: StatusBadge(status: item.status),
                            onTap: () => context.push('/cases/${item.id}'),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/case_provider.dart';
import '../../../config/app_theme.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/list_skeleton_placeholder.dart';
import '../../../data/models/case_model.dart';

/// Admin Case List with search & persistent filter chips (Task 35).
/// Preserves search query, status chip, category chip, and date sorting
/// across navigation (e.g. returning from case details).
class CaseListScreen extends StatefulWidget {
  final String? statusFilter;
  const CaseListScreen({super.key, this.statusFilter});

  @override
  State<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends State<CaseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedStatus;
  String _selectedCategory = 'All';
  bool _sortNewest = true;

  final List<String> _statuses = [
    'All',
    'Pending',
    'Under Investigation',
    'Settled',
    'Closed',
  ];

  final List<String> _categories = [
    'All',
    'Physical Injury',
    'Theft/Robbery',
    'Threats',
    'Noise Complaint',
    'Property Damage',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.statusFilter ?? 'All';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applySearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    final statusParam = _selectedStatus == 'All' ? null : _selectedStatus;
    context.read<CaseProvider>().fetchCases(
      query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      status: statusParam,
    );
  }

  List<CaseModel> _filterAndSortCases(List<CaseModel> rawList) {
    var filtered = List<CaseModel>.from(rawList);

    // In-memory category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((c) {
        final cat = c.complaint?.typeName ?? '';
        return cat.toLowerCase().contains(_selectedCategory.toLowerCase());
      }).toList();
    }

    // Sort by date
    filtered.sort((a, b) {
      final dateA = a.updatedAt;
      final dateB = b.updatedAt;
      return _sortNewest ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final caseProvider = context.watch<CaseProvider>();
    final displayCases = _filterAndSortCases(caseProvider.cases);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mga Kaso at Blotter (Case List)'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter Header Container
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Maghanap ng Case #, pangalan, o detalye...',
                    hintStyle: TextStyle(fontSize: 13, color: isDark ? AppTheme.textHintDark : AppTheme.textHintLight),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _applySearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    ),
                  ),
                  onSubmitted: (_) => _applySearch(),
                  onChanged: (val) {
                    if (val.isEmpty) _applySearch();
                  },
                ),
                const SizedBox(height: AppTheme.space8),

                // Status Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statuses.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final s = _statuses[i];
                      final isSelected = _selectedStatus == s;
                      return ChoiceChip(
                        label: Text(s, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedStatus = s);
                            _applySearch();
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.space8),

                // Category & Date Sorting Row
                Row(
                  children: [
                    // Category Dropdown / Filter
                    Expanded(
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c == 'All' ? 'Lahat ng Kategorya' : c,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    // Date Sort Toggle
                    InkWell(
                      onTap: () => setState(() => _sortNewest = !_sortNewest),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                        ),
                        child: Row(
                          children: [
                            Icon(_sortNewest ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _sortNewest ? 'Pinakabago' : 'Pinakaluma',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main List View
          Expanded(
            child: caseProvider.isLoading && caseProvider.cases.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ListSkeletonPlaceholder(itemCount: 5),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _applySearch(),
                    child: displayCases.isEmpty
                        ? EmptyStateView(
                            icon: Icons.folder_open_rounded,
                            title: 'Walang nahanap na kaso',
                            message: 'Subukang baguhin ang mga filter chip o search query.',
                            actionLabel: 'I-reset ang Filter',
                            onAction: () {
                              setState(() {
                                _searchController.clear();
                                _selectedStatus = 'All';
                                _selectedCategory = 'All';
                              });
                              _applySearch();
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: displayCases.length,
                            itemBuilder: (context, index) {
                              final item = displayCases[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => context.push('/cases/${item.id}'),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Kaso #${item.caseNumber}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ),
                                            StatusBadge(status: item.status, compact: true),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.complaint?.typeName ?? 'Reklamo',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.complaint?.details ?? 'Walang nakalagay na detalye',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_outlined, size: 12, color: isDark ? AppTheme.textHintDark : AppTheme.textHintLight),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(item.updatedAt),
                                              style: TextStyle(fontSize: 11, color: isDark ? AppTheme.textHintDark : AppTheme.textHintLight),
                                            ),
                                            const Spacer(),
                                            const Icon(Icons.chevron_right, size: 16),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

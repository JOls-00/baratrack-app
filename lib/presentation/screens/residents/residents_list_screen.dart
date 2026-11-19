import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/resident_provider.dart';

class ResidentsListScreen extends StatefulWidget {
  const ResidentsListScreen({super.key});

  @override
  State<ResidentsListScreen> createState() => _ResidentsListScreenState();
}

class _ResidentsListScreenState extends State<ResidentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedZone;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ResidentProvider>().fetchResidents();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return context.read<ResidentProvider>().fetchResidents(query: _searchController.text, zone: _selectedZone);
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final residentProvider = context.watch<ResidentProvider>();

    Widget body;
    if (residentProvider.isLoading && residentProvider.residents.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: residentProvider.residents.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Icon(
                            residentProvider.error != null ? Icons.error_outline : Icons.people_outline,
                            size: 48,
                            color: residentProvider.error != null ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            residentProvider.error != null
                                ? 'Failed to load residents.\n${residentProvider.error}'
                                : 'No residents found.',
                            textAlign: TextAlign.center,
                          ),
                          if (residentProvider.error != null) ...[
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: residentProvider.residents.length,
                itemBuilder: (context, index) {
                  final resident = residentProvider.residents[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(resident.firstName.isNotEmpty ? resident.firstName[0] : '?', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(resident.fullName, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      subtitle: Text('Zone ${resident.zone ?? 'N/A'} • ${resident.contact ?? 'No Contact'}', overflow: TextOverflow.ellipsis),
                      trailing: _statusChip(resident.status),
                      onTap: () => context.push('/residents/${resident.id}'),
                    ),
                  );
                },
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Residents Directory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search residents by name or contact...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All Zones'),
                    selected: _selectedZone == null,
                    onSelected: (_) {
                      setState(() => _selectedZone = null);
                      _refresh();
                    },
                  ),
                ),
                for (final z in const ['1', '2', '3', '4', '5', '6', '7'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('Zone $z'),
                      selected: _selectedZone == z,
                      onSelected: (_) {
                        setState(() => _selectedZone = z);
                        _refresh();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/residents/new'),
        label: const Text('Register Resident'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.green;
    if (status == 'Deceased') color = Colors.red;
    if (status == 'Relocated') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

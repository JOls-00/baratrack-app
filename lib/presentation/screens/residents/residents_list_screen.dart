import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/resident_provider.dart';
import '../../../data/models/resident_model.dart';
import '../../../config/app_theme.dart';

class ResidentsListScreen extends StatefulWidget {
  const ResidentsListScreen({super.key});

  @override
  State<ResidentsListScreen> createState() => _ResidentsListScreenState();
}

class _ResidentsListScreenState extends State<ResidentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedZone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResidentProvider>().fetchResidents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final residentProvider = context.watch<ResidentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Residents Directory'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedZone,
              hint: const Text('Filter by Zone'),
              underline: const SizedBox(),
              items: ['1', '2', '3', '4', '5', '6', '7'].map((z) => DropdownMenuItem(value: z, child: Text('Zone $z'))).toList(),
              onChanged: (val) {
                setState(() => _selectedZone = val);
                residentProvider.fetchResidents(query: _searchController.text, zone: val);
              },
            ),
          ),
          if (_selectedZone != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                setState(() => _selectedZone = null);
                residentProvider.fetchResidents(query: _searchController.text);
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search residents by name or contact...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: (value) => residentProvider.fetchResidents(query: value, zone: _selectedZone),
            ),
          ),
        ),
      ),
      body: residentProvider.isLoading && residentProvider.residents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => residentProvider.fetchResidents(query: _searchController.text, zone: _selectedZone),
              child: residentProvider.residents.isEmpty
                  ? const Center(child: Text('No residents found.'))
                  : ListView.builder(
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
                            title: Text(resident.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Zone ${resident.zone ?? 'N/A'} • ${resident.contact ?? 'No Contact'}'),
                            trailing: _statusChip(resident.status),
                            onTap: () => context.push('/residents/${resident.id}'),
                          ),
                        );
                      },
                    ),
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

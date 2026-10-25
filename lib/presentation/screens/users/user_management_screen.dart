import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../config/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['Pending Approval', 'Active', 'Inactive', 'All'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsersForCurrentTab();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadUsersForCurrentTab();
    }
  }

  String? get _currentStatusFilter {
    switch (_tabController.index) {
      case 0:
        return 'Pending';
      case 1:
        return 'Active';
      case 2:
        return 'Inactive';
      case 3:
      default:
        return null;
    }
  }

  void _loadUsersForCurrentTab() {
    context.read<UserProvider>().fetchUsers(status: _currentStatusFilter);
  }

  Future<void> _approve(UserModel user) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<UserProvider>().approveUser(user.id, currentStatusFilter: _currentStatusFilter);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Account for ${user.name} approved!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to approve: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reject(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Account?'),
        content: Text('Are you sure you want to reject ${user.name}\'s account? Its status will be set to Inactive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await context.read<UserProvider>().rejectUser(user.id, currentStatusFilter: _currentStatusFilter);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Account for ${user.name} rejected.'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadUsersForCurrentTab(),
              child: userProvider.users.isEmpty
                  ? Center(
                      child: Text(
                        'No accounts found in this status.',
                        style: TextStyle(color: theme.hintColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: userProvider.users.length,
                      itemBuilder: (context, index) {
                        final user = userProvider.users[index];
                        final isPending = user.status == 'Pending';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0] : '?',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    user.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${user.role} • ${user.email}'),
                                      if (user.username != null && user.username!.isNotEmpty)
                                        Text('Username: @${user.username}', style: const TextStyle(fontSize: 12)),
                                      if (user.idNumber != null && user.idNumber!.isNotEmpty)
                                        Text('ID Number: ${user.idNumber}', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  trailing: _statusChip(user.status),
                                ),
                                if (isPending) ...[
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                        onPressed: () => _reject(user),
                                        icon: const Icon(Icons.close, size: 16),
                                        label: const Text('Reject'),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => _approve(user),
                                        icon: const Icon(Icons.check, size: 16),
                                        label: const Text('Approve'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.green;
    if (status == 'Inactive') color = Colors.red;
    if (status == 'Pending') color = Colors.amber.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

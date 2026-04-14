import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/query_model.dart';
import '../../services/query_service.dart';
import 'client_drawer.dart';

/// Client Queries & Complaints Screen
class ClientQueriesScreen extends StatefulWidget {
  const ClientQueriesScreen({super.key});

  @override
  State<ClientQueriesScreen> createState() => _ClientQueriesScreenState();
}

class _ClientQueriesScreenState extends State<ClientQueriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final QueryService _queryService = QueryService();
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get userName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Client';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Check if we need to open new query dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args?['openNew'] == true) {
        _showNewQueryDialog(subject: args?['subject']);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Queries & Complaints',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      drawer: const ClientDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.royalBlue,
        onPressed: () => _showNewQueryDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Query', style: TextStyle(color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQueriesList(AppConstants.queryPending),
          _buildQueriesList(AppConstants.queryInProgress),
          _buildQueriesList(AppConstants.queryCompleted),
        ],
      ),
    );
  }

  Widget _buildQueriesList(String status) {
    return StreamBuilder<List<QueryModel>>(
      stream: _queryService.getClientQueries(userId, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final queries = snapshot.data ?? [];

        if (queries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == AppConstants.queryCompleted
                      ? Icons.check_circle_outline
                      : Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  status == AppConstants.queryPending
                      ? 'No pending queries'
                      : status == AppConstants.queryInProgress
                      ? 'No queries in progress'
                      : 'No completed queries',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                if (status == AppConstants.queryPending) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: () => _showNewQueryDialog(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Submit a Query',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: queries.length,
          itemBuilder: (context, index) => _buildQueryCard(queries[index]),
        );
      },
    );
  }

  Widget _buildQueryCard(QueryModel query) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        boxShadow: AppTheme.lightShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      query.category,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(query.category),
                    color: _getCategoryColor(query.category),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        query.subject,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        query.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(query.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              query.description,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (query.adminResponse != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Admin Response:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      query.adminResponse!,
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (query.resolvedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Responded on ${_formatDate(query.resolvedAt)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Submitted: ${_formatDate(query.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case AppConstants.queryPending:
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case AppConstants.queryInProgress:
        color = Colors.blue;
        label = 'In Progress';
        icon = Icons.sync;
        break;
      case AppConstants.queryCompleted:
        color = Colors.green;
        label = 'Completed';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Payment':
        return Colors.green;
      case 'Plot':
        return Colors.blue;
      case 'Documents':
        return Colors.purple;
      case 'Maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Payment':
        return Icons.payment;
      case 'Plot':
        return Icons.landscape;
      case 'Documents':
        return Icons.description;
      case 'Maintenance':
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showNewQueryDialog({String? subject}) {
    final subjectController = TextEditingController(text: subject);
    final descriptionController = TextEditingController();
    String selectedCategory = 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Submit New Query',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: AppTheme.inputDecoration(
                    hint: 'Select category',
                    label: 'Category',
                  ),
                  items:
                      ['General', 'Payment', 'Plot', 'Documents', 'Maintenance']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged: (v) => setModalState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: AppTheme.inputDecoration(
                    hint: 'Enter subject',
                    label: 'Subject',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: AppTheme.inputDecoration(
                    hint: 'Describe your query or complaint in detail...',
                    label: 'Description',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (subjectController.text.isEmpty ||
                          descriptionController.text.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(ctx);

                      final query = QueryModel(
                        id: '',
                        clientId: userId,
                        clientName: userName,
                        clientEmail:
                            FirebaseAuth.instance.currentUser?.email ?? '',
                        subject: subjectController.text,
                        description: descriptionController.text,
                        category: selectedCategory,
                        status: AppConstants.queryPending,
                        createdAt: DateTime.now(),
                      );

                      await _queryService.submitQuery(query);

                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Query submitted successfully'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    },
                    child: const Text(
                      'Submit Query',
                      style: AppTheme.buttonText,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

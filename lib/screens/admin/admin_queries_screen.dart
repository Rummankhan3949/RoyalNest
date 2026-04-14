import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/query_model.dart';
import '../../services/query_service.dart';
import 'admin_drawer.dart';

/// Admin Queries & Complaints Screen
class AdminQueriesScreen extends StatefulWidget {
  const AdminQueriesScreen({super.key});

  @override
  State<AdminQueriesScreen> createState() => _AdminQueriesScreenState();
}

class _AdminQueriesScreenState extends State<AdminQueriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final QueryService _queryService = QueryService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      drawer: const AdminDrawer(),
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
      stream: _queryService.getQueriesByStatus(status),
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
      decoration: AppTheme.cardDecoration,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        query.clientName,
                        style: const TextStyle(
                          fontSize: 12,
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
                    const Text(
                      'Admin Response:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      query.adminResponse!,
                      style: const TextStyle(fontSize: 13),
                    ),
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
                  _formatDate(query.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const Spacer(),
                if (query.status != AppConstants.queryCompleted) ...[
                  TextButton(
                    onPressed: () => _showResponseDialog(query),
                    child: const Text('Respond'),
                  ),
                ],
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

    switch (status) {
      case AppConstants.queryPending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case AppConstants.queryInProgress:
        color = Colors.blue;
        label = 'In Progress';
        break;
      case AppConstants.queryCompleted:
        color = Colors.green;
        label = 'Completed';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
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
      default:
        return Colors.orange;
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
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showResponseDialog(QueryModel query) {
    final responseController = TextEditingController();
    String selectedStatus = query.status == AppConstants.queryPending
        ? AppConstants.queryInProgress
        : AppConstants.queryCompleted;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Respond to Query'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Query: ${query.subject}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: AppTheme.inputDecoration(
                  hint: 'Select Status',
                  label: 'Update Status',
                ),
                items: [
                  DropdownMenuItem(
                    value: AppConstants.queryInProgress,
                    child: const Text('Mark In Progress'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.queryCompleted,
                    child: const Text('Mark Completed'),
                  ),
                ],
                onChanged: (v) => selectedStatus = v!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: responseController,
                maxLines: 4,
                decoration: AppTheme.inputDecoration(
                  hint: 'Enter your response to the client...',
                  label: 'Response',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle,
            onPressed: () async {
              Navigator.pop(ctx);
              await _queryService.updateQueryStatus(
                query.id,
                selectedStatus,
                adminResponse: responseController.text.isNotEmpty
                    ? responseController.text
                    : null,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Query updated and client notified'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

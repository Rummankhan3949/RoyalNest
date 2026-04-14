import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lost_found_model.dart';
import '../../services/lost_found_service.dart';
import 'admin_drawer.dart';

/// Admin Lost & Found Screen
class AdminLostFoundScreen extends StatefulWidget {
  const AdminLostFoundScreen({super.key});

  @override
  State<AdminLostFoundScreen> createState() => _AdminLostFoundScreenState();
}

class _AdminLostFoundScreenState extends State<AdminLostFoundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LostFoundService _lostFoundService = LostFoundService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          'Lost & Found',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Lost'),
            Tab(text: 'Found'),
            Tab(text: 'Claimed'),
            Tab(text: 'Returned'),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemsList(AppConstants.itemLost),
          _buildItemsList(AppConstants.itemFound),
          _buildItemsList(AppConstants.itemClaimed),
          _buildItemsList(AppConstants.itemReturned),
        ],
      ),
    );
  }

  Widget _buildItemsList(String status) {
    return StreamBuilder<List<LostFoundModel>>(
      stream: _lostFoundService.getItemsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No $status items',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildItemCard(items[index]),
        );
      },
    );
  }

  Widget _buildItemCard(LostFoundModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.mediumRadius),
              ),
              child: Image.network(
                item.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
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
                          item.category,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(item.category),
                        color: _getCategoryColor(item.category),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(item.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${item.location}, ${item.society}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Reported by: ${item.reportedBy}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(item.reportedAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                if (item.claimedBy != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Claimed by: ${item.claimedBy}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _buildActionButtons(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LostFoundModel item) {
    switch (item.status) {
      case AppConstants.itemLost:
      case AppConstants.itemFound:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: AppTheme.outlineButtonStyle,
                onPressed: () => _showClaimDialog(item),
                child: const Text('Mark Claimed'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: AppTheme.primaryButtonStyle,
                onPressed: () => _contactReporter(item),
                child: const Text(
                  'Contact',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      case AppConstants.itemClaimed:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => _markAsReturned(item),
            child: const Text(
              'Mark Returned',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case AppConstants.itemLost:
        color = Colors.red;
        label = 'Lost';
        break;
      case AppConstants.itemFound:
        color = Colors.blue;
        label = 'Found';
        break;
      case AppConstants.itemClaimed:
        color = Colors.orange;
        label = 'Claimed';
        break;
      case AppConstants.itemReturned:
        color = Colors.green;
        label = 'Returned';
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
      case 'Keys':
        return Colors.orange;
      case 'Wallet':
        return Colors.green;
      case 'Phone':
        return Colors.blue;
      case 'Documents':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Keys':
        return Icons.key;
      case 'Wallet':
        return Icons.wallet;
      case 'Phone':
        return Icons.phone_android;
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

  void _showClaimDialog(LostFoundModel item) {
    final claimerNameController = TextEditingController();
    final claimerContactController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Claimed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: claimerNameController,
              decoration: AppTheme.inputDecoration(
                hint: 'Enter claimer name',
                label: 'Claimer Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: claimerContactController,
              decoration: AppTheme.inputDecoration(
                hint: 'Enter contact number',
                label: 'Contact',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle,
            onPressed: () async {
              if (claimerNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter claimer name')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _lostFoundService.markAsClaimed(
                item.id,
                claimerNameController.text,
                claimerContactController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item marked as claimed'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _contactReporter(LostFoundModel item) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Contact: ${item.reporterContact}')));
  }

  Future<void> _markAsReturned(LostFoundModel item) async {
    await _lostFoundService.markAsReturned(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item marked as returned'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}

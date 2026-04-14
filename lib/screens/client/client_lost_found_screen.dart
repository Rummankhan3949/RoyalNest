import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lost_found_model.dart';
import '../../services/lost_found_service.dart';
import 'client_drawer.dart';

/// Client Lost & Found Screen
class ClientLostFoundScreen extends StatefulWidget {
  const ClientLostFoundScreen({super.key});

  @override
  State<ClientLostFoundScreen> createState() => _ClientLostFoundScreenState();
}

class _ClientLostFoundScreenState extends State<ClientLostFoundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LostFoundService _lostFoundService = LostFoundService();
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get userName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'User';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args?['openNew'] == true) {
        _showReportItemDialog();
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
          'Lost & Found',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Items'),
            Tab(text: 'My Reports'),
          ],
        ),
      ),
      drawer: const ClientDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.royalBlue,
        onPressed: () => _showReportItemDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Report Item', style: TextStyle(color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAllItemsList(), _buildMyReportsList()],
      ),
    );
  }

  Widget _buildAllItemsList() {
    return StreamBuilder<List<LostFoundModel>>(
      stream: _lostFoundService.getAllItems(),
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
                  'No items reported',
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

  Widget _buildMyReportsList() {
    return StreamBuilder<List<LostFoundModel>>(
      stream: _lostFoundService.getMyReports(userId),
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
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No reports yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: AppTheme.primaryButtonStyle,
                  onPressed: () => _showReportItemDialog(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Report an Item',
                    style: TextStyle(color: Colors.white),
                  ),
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
    final isMyReport = item.reportedById == userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        boxShadow: AppTheme.lightShadow,
      ),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildStatusChip(item.status),
                            ],
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
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${item.location}, ${item.society}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Reported by: ${item.reportedBy}${isMyReport ? ' (You)' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(item.reportedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (item.claimedBy != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Claimed by: ${item.claimedBy}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!isMyReport &&
                    item.status != AppConstants.itemReturned) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: AppTheme.outlineButtonStyle,
                      onPressed: () => _contactReporter(item),
                      icon: const Icon(Icons.phone),
                      label: const Text('Contact Reporter'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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

  void _contactReporter(LostFoundModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Contact Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reporter: ${item.reportedBy}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: AppTheme.royalBlue),
                const SizedBox(width: 8),
                Text(item.reporterContact),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReportItemDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    String selectedCategory = 'Other';
    String selectedType = AppConstants.itemLost;
    String selectedSociety = AppConstants.societies[0];

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Report Lost/Found Item',
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
                    initialValue: selectedType,
                    decoration: AppTheme.inputDecoration(
                      hint: 'Select type',
                      label: 'Type',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: AppConstants.itemLost,
                        child: const Text('Lost'),
                      ),
                      DropdownMenuItem(
                        value: AppConstants.itemFound,
                        child: const Text('Found'),
                      ),
                    ],
                    onChanged: (v) => setModalState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: AppTheme.inputDecoration(
                      hint: 'Select category',
                      label: 'Category',
                    ),
                    items: ['Keys', 'Wallet', 'Phone', 'Documents', 'Other']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: AppTheme.inputDecoration(
                      hint: 'Enter item title',
                      label: 'Title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: AppTheme.inputDecoration(
                      hint: 'Describe the item in detail...',
                      label: 'Description',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSociety,
                    decoration: AppTheme.inputDecoration(
                      hint: 'Select society',
                      label: 'Society',
                    ),
                    items: AppConstants.societies
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedSociety = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: AppTheme.inputDecoration(
                      hint: 'Specific location (e.g., Block A, Gate 1)',
                      label: 'Location',
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
                        if (titleController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            locationController.text.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all fields'),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(ctx);

                        final item = LostFoundModel(
                          id: '',
                          title: titleController.text,
                          description: descriptionController.text,
                          category: selectedCategory,
                          status: selectedType,
                          reportedById: userId,
                          reportedBy: userName,
                          reporterContact:
                              FirebaseAuth.instance.currentUser?.phoneNumber ??
                              'Not provided',
                          society: selectedSociety,
                          location: locationController.text,
                          reportedAt: DateTime.now(),
                        );

                        await _lostFoundService.reportItem(item);

                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Item reported successfully'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      },
                      child: const Text(
                        'Submit Report',
                        style: AppTheme.buttonText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

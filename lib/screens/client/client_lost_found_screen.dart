import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/claim_model.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isRefreshingToken = false;
  DateTime? _lastPermissionRefresh;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

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
            Tab(text: 'Claim Requests'),
          ],
        ),
      ),
      drawer: const ClientDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.royalBlue,
        onPressed: () => _handleReportAction(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Report Item', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.idTokenChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUser = authSnapshot.data;
          if (currentUser == null) {
            return _buildAuthRequiredMessage(
              'Please sign in to use Lost & Found.',
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllItemsList(currentUser.uid),
              _buildMyReportsList(currentUser.uid),
              _buildClaimRequestsList(currentUser.uid),
            ],
          );
        },
      ),
    );
  }

  User? _currentUserOrPrompt() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to continue.')),
        );
      }
    }
    return user;
  }

  void _handleReportAction() {
    final user = _currentUserOrPrompt();
    if (user == null) return;
    _showReportItemDialog();
  }

  void _recoverFromPermissionDenied(Object? error) {
    final errorText = error?.toString() ?? '';
    if (!errorText.contains('permission-denied')) return;
    if (_isRefreshingToken) return;
    final lastRefresh = _lastPermissionRefresh;
    if (lastRefresh != null &&
        DateTime.now().difference(lastRefresh).inSeconds < 10) {
      return;
    }

    _isRefreshingToken = true;
    _lastPermissionRefresh = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
      } finally {
        if (mounted) {
          setState(() => _isRefreshingToken = false);
        } else {
          _isRefreshingToken = false;
        }
      }
    });
  }

  Widget _buildAuthRequiredMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAllItemsList(String currentUserId) {
    if (currentUserId.isEmpty) {
      return _buildAuthRequiredMessage('Sign in to view all items.');
    }
    return StreamBuilder<List<LostFoundModel>>(
      stream: _lostFoundService.getAllItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          _recoverFromPermissionDenied(snapshot.error);
          final errorText = snapshot.error?.toString() ?? 'Unknown error';
          final readable = errorText.contains('permission-denied')
              ? 'Permission denied. Please sign in again.'
              : 'Failed to load items. Please try again.';
          return Center(child: Text(readable));
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
          itemBuilder: (context, index) =>
              _buildItemCard(items[index], currentUserId),
        );
      },
    );
  }

  Widget _buildMyReportsList(String currentUserId) {
    if (currentUserId.isEmpty) {
      return _buildAuthRequiredMessage('Sign in to view your reports.');
    }
    return StreamBuilder<List<LostFoundModel>>(
      stream: _lostFoundService.getMyReports(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          _recoverFromPermissionDenied(snapshot.error);
          final errorText = snapshot.error?.toString() ?? 'Unknown error';
          final readable = errorText.contains('permission-denied')
              ? 'Permission denied. Please sign in again.'
              : 'Failed to load reports. Please try again.';
          return Center(child: Text(readable));
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
          itemBuilder: (context, index) =>
              _buildItemCard(items[index], currentUserId),
        );
      },
    );
  }

  Widget _buildItemCard(LostFoundModel item, String currentUserId) {
    final isMyReport = item.reportedById == currentUserId;
    final canClaim =
        !isMyReport &&
        item.isClaimable &&
        (item.claimedBy == null || item.claimedBy!.isEmpty);

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
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                child: _buildStatusChip(item.lifecycleStatus),
                              ),
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
                if (!isMyReport) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: AppTheme.primaryButtonStyle,
                      onPressed: canClaim ? () => _showClaimForm(item) : null,
                      icon: const Icon(Icons.assignment_turned_in),
                      label: const Text(
                        'Claim Item',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (!canClaim) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.lifecycleStatus == AppConstants.itemActive
                          ? 'Claim unavailable for this item.'
                          : 'This item is no longer active.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
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
      case AppConstants.itemActive:
        color = Colors.blue;
        label = 'Active';
        break;
      case AppConstants.itemClaimed:
        color = Colors.orange;
        label = 'Claimed';
        break;
      case AppConstants.itemResolved:
      case AppConstants.itemReturned:
        color = Colors.green;
        label = 'Resolved';
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
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 280),
      ),
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
                        final currentUser = _currentUserOrPrompt();
                        if (currentUser == null) return;

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

                        final userId = currentUser.uid;
                        final userName = currentUser.displayName ?? 'User';

                        final item = LostFoundModel(
                          id: '',
                          title: titleController.text,
                          description: descriptionController.text,
                          category: selectedCategory,
                          type: selectedType,
                          status: AppConstants.itemActive,
                          reportedById: userId,
                          reportedBy: userName,
                          reporterContact:
                              currentUser.phoneNumber ?? 'Not provided',
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

  Widget _buildClaimRequestsList(String currentUserId) {
    if (currentUserId.isEmpty) {
      return _buildAuthRequiredMessage('Sign in to view claim requests.');
    }
    return StreamBuilder<List<ClaimModel>>(
      stream: _lostFoundService.getClaimRequestsForOwner(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          _recoverFromPermissionDenied(snapshot.error);
          final errorText = snapshot.error?.toString() ?? 'Unknown error';
          final readable = errorText.contains('permission-denied')
              ? 'Permission denied. Please sign in again.'
              : 'Failed to load claim requests. Please try again.';
          return Center(child: Text(readable));
        }
        final claims = snapshot.data ?? [];
        if (claims.isEmpty) {
          return Center(
            child: Text(
              'No pending claim requests',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: claims.length,
          itemBuilder: (context, index) =>
              _buildClaimRequestCard(claims[index]),
        );
      },
    );
  }

  Widget _buildClaimRequestCard(ClaimModel claim) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Claimant: ${claim.claimantName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text('Proof: ${claim.proofText}'),
            if (claim.proofImageUrl != null && claim.proofImageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    claim.proofImageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => _approveClaim(claim),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Approve',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: AppTheme.outlineButtonStyle,
                    onPressed: () => _rejectClaim(claim),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClaimForm(LostFoundModel item) async {
    final proofController = TextEditingController();
    File? selectedImage;
    bool isSubmitting = false;
    final currentUser = _currentUserOrPrompt();
    if (currentUser == null) return;
    final userId = currentUser.uid;
    final userName = currentUser.displayName ?? 'User';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 300),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickImage() async {
            final image = await _imagePicker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
            );
            if (image == null) return;
            setModalState(() => selectedImage = File(image.path));
          }

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
                  const Text(
                    'Claim Item',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: proofController,
                    maxLines: 4,
                    decoration: AppTheme.inputDecoration(
                      hint: 'Describe proof of ownership...',
                      label: 'Proof Description',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: AppTheme.outlineButtonStyle,
                    onPressed: pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      selectedImage == null
                          ? 'Upload Proof Image (Optional)'
                          : 'Image Selected',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: AppTheme.primaryButtonStyle,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              if (proofController.text.trim().isEmpty) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Proof description is required.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);
                              try {
                                String? proofImageUrl;
                                if (selectedImage != null) {
                                  proofImageUrl = await _lostFoundService
                                      .uploadClaimProofImage(
                                        file: selectedImage!,
                                        userId: userId,
                                        itemId: item.id,
                                      );
                                }

                                await _lostFoundService.createClaim(
                                  item: item,
                                  claimantUserId: userId,
                                  claimantName: userName,
                                  proofText: proofController.text.trim(),
                                  proofImageUrl: proofImageUrl,
                                );
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Claim request submitted'),
                                    backgroundColor: AppTheme.successColor,
                                  ),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              } finally {
                                if (context.mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Submit Claim',
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

  Future<void> _approveClaim(ClaimModel claim) async {
    final ok = await _lostFoundService.approveClaim(
      claimId: claim.id,
      itemId: claim.itemId,
      claimantUserId: claim.claimantUserId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Claim approved successfully' : 'Failed to approve'),
        backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  Future<void> _rejectClaim(ClaimModel claim) async {
    final ok = await _lostFoundService.rejectClaim(
      claimId: claim.id,
      claimantUserId: claim.claimantUserId,
      itemId: claim.itemId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Claim rejected' : 'Failed to reject'),
        backgroundColor: ok ? Colors.orange : AppTheme.errorColor,
      ),
    );
  }
}

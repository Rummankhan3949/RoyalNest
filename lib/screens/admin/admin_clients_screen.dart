import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/payment_model.dart';
import '../../models/plot_model.dart';
import '../../models/user_model.dart';
import '../../services/client_service.dart';
import 'admin_drawer.dart';

/// Admin Clients Details Screen
class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  final ClientService _clientService = ClientService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'latest';
  bool _updatingUserBlock = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        title: const Text(
          'Registered Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration:
                  AppTheme.inputDecoration(
                    hint: 'Search by name, email, or CNIC...',
                    label: 'Search Registered Users',
                  ).copyWith(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                const Text(
                  'Sort:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'latest', child: Text('Latest')),
                    DropdownMenuItem(value: 'name', child: Text('Name A-Z')),
                    DropdownMenuItem(
                      value: 'blocked_first',
                      child: Text('Blocked First'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _sortBy = value);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _clientService.getRegisteredUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorState(
                    'Unable to load registered clients right now.',
                  );
                }

                final clients = snapshot.data ?? [];

                // Filter clients based on search query
                var filteredClients = _searchQuery.isEmpty
                    ? clients
                    : clients.where((client) {
                        final query = _searchQuery.toLowerCase();
                        return client.username.toLowerCase().contains(query) ||
                            client.email.toLowerCase().contains(query) ||
                            client.cnic.toLowerCase().contains(query);
                      }).toList();

                if (_sortBy == 'name') {
                  filteredClients.sort(
                    (a, b) => a.username.toLowerCase().compareTo(
                      b.username.toLowerCase(),
                    ),
                  );
                } else if (_sortBy == 'blocked_first') {
                  filteredClients.sort((a, b) {
                    if (a.isBlocked == b.isBlocked) return 0;
                    return a.isBlocked ? -1 : 1;
                  });
                } else {
                  filteredClients.sort((a, b) {
                    final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
                    final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
                    return bTime.compareTo(aTime);
                  });
                }

                if (filteredClients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No clients found'
                              : 'No matching clients',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Registered Users (${filteredClients.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredClients.length,
                        itemBuilder: (context, index) =>
                            _buildClientCard(filteredClients[index]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(UserModel client) {
    final displayName = client.username.trim().isEmpty
        ? (client.email.trim().isEmpty
              ? 'Client'
              : client.email.trim().split('@').first)
        : client.username.trim();
    final email = client.email.trim().isEmpty
        ? 'No email available'
        : client.email.trim();
    final cnic = client.cnic.trim().isEmpty ? '-' : client.cnic.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.lightShadow,
      ),
      child: InkWell(
        onTap: () => _showClientDetails(client),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.royalBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryTextColor,
                            ),
                          ),
                        ),
                        if (client.isDocumentsVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.verified,
                              size: 18,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CNIC: $cnic',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: client.isBlocked
                          ? Colors.red.withValues(alpha: 0.12)
                          : Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      client.isBlocked ? 'Blocked' : 'Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: client.isBlocked ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Transform.scale(
                    scale: 0.82,
                    child: Switch(
                      value: !client.isBlocked,
                      onChanged: _updatingUserBlock
                          ? null
                          : (isActive) => _toggleBlockStatus(
                              client,
                              shouldBlock: !isActive,
                            ),
                    ),
                  ),
                  if (client.isFiler)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Filer',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.secondaryTextColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBlockStatus(
    UserModel user, {
    required bool shouldBlock,
  }) async {
    setState(() => _updatingUserBlock = true);

    final ok = await _clientService.updateUserBlockStatus(
      userId: user.uid,
      isBlocked: shouldBlock,
    );

    if (!mounted) return;
    setState(() => _updatingUserBlock = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (shouldBlock
                    ? 'User blocked successfully.'
                    : 'User unblocked successfully.')
              : 'Unable to update user status.',
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  void _showClientDetails(UserModel client) {
    if (client.uid.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client record is incomplete. Unable to open details.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _ClientDetailSheet(
          client: client,
          clientService: _clientService,
          scrollController: scrollController,
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientDetailSheet extends StatelessWidget {
  final UserModel client;
  final ClientService clientService;
  final ScrollController scrollController;

  const _ClientDetailSheet({
    required this.client,
    required this.clientService,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: clientService.getClientDetails(client.uid),
      builder: (context, snapshot) {
        final hasError = snapshot.hasError;
        return Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.royalBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        client.username.isNotEmpty
                            ? client.username[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.royalBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                client.username.isEmpty
                                    ? 'Client'
                                    : client.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (client.isDocumentsVerified) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified,
                                size: 20,
                                color: Colors.green,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          client.email.isEmpty
                              ? 'No email available'
                              : client.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : hasError
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Unable to load client details right now.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.secondaryTextColor),
                        ),
                      ),
                    )
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildInfoSection(context, snapshot.data),
                        const SizedBox(height: 20),
                        _buildPlotsSection(context, snapshot.data),
                        const SizedBox(height: 20),
                        _buildPaymentsSection(context, snapshot.data),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context, Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('CNIC', client.cnic),
          _buildInfoRow('Filer Status', client.isFiler ? 'Yes' : 'No'),
          _buildInfoRow(
            'Account Status',
            client.isBlocked ? 'Blocked' : 'Active',
            valueColor: client.isBlocked ? Colors.red : Colors.green,
          ),
          _buildInfoRow(
            'Documents',
            client.isDocumentsVerified ? 'Verified' : 'Pending',
            valueColor: client.isDocumentsVerified
                ? Colors.green
                : Colors.orange,
          ),
          _buildInfoRow(
            'Joined',
            client.createdAt != null
                ? '${client.createdAt!.day}/${client.createdAt!.month}/${client.createdAt!.year}'
                : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPlotsSection(BuildContext context, Map<String, dynamic>? data) {
    final rawPlots = (data?['plots'] as List<dynamic>?) ?? [];
    final plots = rawPlots
        .map((item) {
          if (item is PlotModel) {
            return item;
          }

          if (item is Map<String, dynamic>) {
            return PlotModel.fromMap(item, item['id']?.toString() ?? '');
          }

          return null;
        })
        .whereType<PlotModel>()
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Owned Plots',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${plots.length} Plot${plots.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.royalBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (plots.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No plots owned',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...plots.map(
              (plot) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.royalBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.landscape,
                        color: AppTheme.royalBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plot.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${plot.society} • ${plot.size} • Block ${plot.blockName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatAmount(plot.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.royalBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection(
    BuildContext context,
    Map<String, dynamic>? data,
  ) {
    final rawPayments = (data?['payments'] as List<dynamic>?) ?? [];
    final payments = rawPayments
        .map((item) {
          if (item is PaymentModel) {
            return item;
          }

          if (item is Map<String, dynamic>) {
            return PaymentModel.fromMap(item, item['id']?.toString() ?? '');
          }

          return null;
        })
        .whereType<PaymentModel>()
        .toList();

    double totalAmount = 0;
    double paidAmount = 0;

    for (final payment in payments) {
      totalAmount += payment.totalAmount;
      paidAmount += payment.paidAmount;
    }

    final remainingAmount = totalAmount - paidAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPaymentStatCard(
                  'Total',
                  _formatAmount(totalAmount),
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentStatCard(
                  'Paid',
                  _formatAmount(paidAmount),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentStatCard(
                  'Remaining',
                  _formatAmount(remainingAmount),
                  Colors.orange,
                ),
              ),
            ],
          ),
          if (payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...payments.map((payment) {
              final total = payment.totalAmount;
              final paid = payment.paidAmount;
              final progress = total > 0 ? (paid / total) : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.plotDetails.isEmpty
                          ? 'Plot Payment'
                          : payment.plotDetails,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatAmount(paid)} / ${_formatAmount(total)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.royalBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress > 0.8 ? Colors.green : Colors.blue,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return 'PKR ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return 'PKR ${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      return 'PKR ${amount.toStringAsFixed(0)}';
    }
  }
}

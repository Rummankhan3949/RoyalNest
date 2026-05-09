import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/payment_method_model.dart';
import '../../services/manual_payment_service.dart';
import 'admin_drawer.dart';

class AdminPaymentMethodsScreen extends StatefulWidget {
  const AdminPaymentMethodsScreen({super.key});

  @override
  State<AdminPaymentMethodsScreen> createState() =>
      _AdminPaymentMethodsScreenState();
}

class _AdminPaymentMethodsScreenState extends State<AdminPaymentMethodsScreen> {
  final ManualPaymentService _service = ManualPaymentService();

  Future<void> _seedDefaults() async {
    final ok = await _service.seedDefaultPaymentMethodsIfEmpty();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Default payment methods are ready.'
              : 'Could not create defaults: ${_service.lastError ?? 'unknown error'}',
        ),
      ),
    );
  }

  Future<void> _showMethodDialog({PaymentMethodModel? method}) async {
    final methodCtrl = TextEditingController(text: method?.methodName ?? '');
    final titleCtrl = TextEditingController(text: method?.accountTitle ?? '');
    final numberCtrl = TextEditingController(text: method?.accountNumber ?? '');
    final bankIdCtrl = TextEditingController(text: method?.bankId ?? '');
    final societyCtrl = TextEditingController(text: method?.societyName ?? '');
    bool active = method?.isActive ?? true;

    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
            method == null ? 'Add Payment Method' : 'Edit Payment Method',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: methodCtrl,
                  decoration: const InputDecoration(labelText: 'Method Name'),
                ),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Account Title'),
                ),
                TextField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account Number / IBAN',
                  ),
                ),
                TextField(
                  controller: bankIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bank ID (shown on challan)',
                  ),
                ),
                TextField(
                  controller: societyCtrl,
                  decoration: const InputDecoration(labelText: 'Society Name'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  onChanged: (v) => setStateDialog(() => active = v),
                  title: const Text('Active'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (submit != true) return;

    if (methodCtrl.text.trim().isEmpty ||
        titleCtrl.text.trim().isEmpty ||
        numberCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    bool ok;
    if (method == null) {
      ok = await _service.addPaymentMethod(
        PaymentMethodModel(
          id: '',
          methodName: methodCtrl.text.trim(),
          accountTitle: titleCtrl.text.trim(),
          accountNumber: numberCtrl.text.trim(),
          bankId: bankIdCtrl.text.trim(),
          societyName: societyCtrl.text.trim(),
          isActive: active,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      ok = await _service.updatePaymentMethod(
        method.copyWith(
          methodName: methodCtrl.text.trim(),
          accountTitle: titleCtrl.text.trim(),
          accountNumber: numberCtrl.text.trim(),
          bankId: bankIdCtrl.text.trim(),
          societyName: societyCtrl.text.trim(),
          isActive: active,
          updatedAt: DateTime.now(),
        ),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Saved successfully.'
              : 'Could not save method: ${_service.lastError ?? 'permission or network issue'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        title: const Text(
          'Payment Methods',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _seedDefaults,
            icon: const Icon(Icons.playlist_add_check, color: Colors.white),
            tooltip: 'Seed default methods',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.royalBlue,
        onPressed: () => _showMethodDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Method', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<PaymentMethodModel>>(
        stream: _service.getAllPaymentMethods(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Could not load payment methods.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final methods = snapshot.data ?? [];
          if (methods.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No payment methods yet.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _seedDefaults,
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Add Default Methods'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.methodName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              method.accountTitle,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              method.accountNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (method.bankId.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Bank ID: ${method.bankId}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                            if (method.societyName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Society: ${method.societyName}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: method.isActive,
                            onChanged: (value) async {
                              final ok = await _service.togglePaymentMethod(
                                method.id,
                                value,
                              );
                              if (ok) return;
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not update status: ${_service.lastError ?? 'permission or network issue'}',
                                  ),
                                ),
                              );
                            },
                          ),
                          TextButton(
                            onPressed: () => _showMethodDialog(method: method),
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

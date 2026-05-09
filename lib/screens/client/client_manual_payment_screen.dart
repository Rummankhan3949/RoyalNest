import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../models/manual_payment_model.dart';
import '../../models/payment_method_model.dart';
import '../../services/manual_payment_service.dart';

enum PaymentFlowMode { online, manual }

class ClientManualPaymentScreen extends StatefulWidget {
  final String propertyId;
  final String propertyName;
  final double amount;
  final String? heroTag;
  final String? linkedPaymentId;
  final int? installmentNumber;
  final String? installmentType;
  final bool isOnlineFlow;
  final bool hasVoucher;
  final String initialMode;
  final Future<bool> Function()? onDownloadChallan;

  const ClientManualPaymentScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
    required this.amount,
    this.heroTag,
    this.linkedPaymentId,
    this.installmentNumber,
    this.installmentType,
    this.isOnlineFlow = false,
    this.hasVoucher = false,
    this.initialMode = 'online',
    this.onDownloadChallan,
  });

  @override
  State<ClientManualPaymentScreen> createState() =>
      _ClientManualPaymentScreenState();
}

class _ClientManualPaymentScreenState extends State<ClientManualPaymentScreen>
    with SingleTickerProviderStateMixin {
  final ManualPaymentService _paymentService = ManualPaymentService();
  final ImagePicker _picker = ImagePicker();

  PaymentMethodModel? _selectedMethod;
  File? _proofImage;
  String? _uploadedProofUrl;

  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _hasSentMoney = false;
  bool _challanDownloaded = false;
  double _uploadProgress = 0;
  PaymentFlowMode _mode = PaymentFlowMode.online;

  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode == 'manual'
        ? PaymentFlowMode.manual
        : PaymentFlowMode.online;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    return 'PKR ${amount.toStringAsFixed(0)}';
  }

  User? get _firebaseUser => FirebaseAuth.instance.currentUser;

  bool get _isOnlineMode => _mode == PaymentFlowMode.online;

  bool get _isFirstInstallmentFlow =>
      (widget.installmentType ?? '').toLowerCase() == 'first_installment' ||
      (widget.installmentNumber ?? 1) <= 1;

  String get _installmentTitle {
    final number = widget.installmentNumber;
    if (number != null && number > 0) {
      return 'Installment #$number';
    }
    return _isFirstInstallmentFlow
        ? 'First Installment'
        : 'Current Installment';
  }

  bool get _canUploadProof {
    if (_isOnlineMode) {
      return _selectedMethod != null && _hasSentMoney;
    }
    return _challanDownloaded && _hasSentMoney;
  }

  Future<void> _downloadChallan() async {
    if (widget.onDownloadChallan == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challan is not available right now.')),
      );
      return;
    }

    final ok = await widget.onDownloadChallan!();
    if (!mounted) return;
    if (ok) {
      setState(() => _challanDownloaded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challan downloaded successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed. Please try again.')),
      );
    }
  }

  Future<void> _copyText(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked == null) return;
      setState(() {
        _proofImage = File(picked.path);
        _uploadedProofUrl = null;
        _uploadProgress = 0;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not pick image. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showPickOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProof() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _proofImage == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    final url = await _paymentService.uploadPaymentProof(
      file: _proofImage!,
      userId: user.uid,
      propertyId: widget.propertyId,
      onProgress: (progress) {
        if (!mounted) return;
        setState(() => _uploadProgress = progress);
      },
    );

    if (!mounted) return;
    setState(() {
      _isUploading = false;
      _uploadedProofUrl = url;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          url != null
              ? 'Proof uploaded successfully.'
              : (_paymentService.lastError ??
                    'Upload failed. Check your connection and retry.'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitManualPayment() async {
    final user = _firebaseUser;
    if (user == null) return;

    if (_isOnlineMode && _selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }

    if (!_isOnlineMode && !_challanDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please download challan before uploading proof.'),
        ),
      );
      return;
    }

    if (!_hasSentMoney) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that you have sent the payment first.'),
        ),
      );
      return;
    }

    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload payment proof screenshot.'),
        ),
      );
      return;
    }

    if (_uploadedProofUrl == null) {
      await _uploadProof();
      if (_uploadedProofUrl == null) return;
    }

    setState(() => _isSubmitting = true);

    final model = ManualPaymentModel(
      id: '',
      userId: user.uid,
      userName: user.displayName ?? 'Client',
      userEmail: user.email ?? '',
      propertyId: widget.propertyId,
      propertyName: widget.propertyName,
      amount: widget.amount,
      paymentMethod: _isOnlineMode
          ? (_selectedMethod?.methodName ?? 'Online')
          : 'Manual-Challan',
      accountNumberUsed: _isOnlineMode
          ? (_selectedMethod?.accountNumber ?? '')
          : 'challan',
      screenshotUrl: _uploadedProofUrl!,
      linkedPaymentId: widget.linkedPaymentId,
      installmentNumber: widget.installmentNumber,
      installmentType: widget.installmentType,
      status: ManualPaymentStatus.pending,
      createdAt: DateTime.now(),
    );

    final ok = await _paymentService.createManualPayment(model);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit payment. Try again.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment submitted. Waiting for admin verification.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushReplacementNamed(context, '/client-manual-payments');
  }

  Widget _buildStepIndicator() {
    final hasMethod = _selectedMethod != null && _hasSentMoney;
    final hasProof = _proofImage != null;
    final uploaded = _uploadedProofUrl != null;

    Widget step(int index, String title, bool active) {
      return Expanded(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppTheme.royalBlue : Colors.grey.shade300,
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: active ? AppTheme.royalBlue : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        step(1, 'Send Payment', hasMethod),
        step(2, 'Upload Proof', hasProof && uploaded),
        step(3, 'Confirmation', hasMethod && uploaded),
      ],
    );
  }

  Widget _buildMethodCard(PaymentMethodModel method) {
    final isSelected = _selectedMethod?.id == method.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppTheme.royalBlue : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: AppTheme.lightShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selectedMethod = method),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    method.methodName.toLowerCase().contains('bank')
                        ? Icons.account_balance
                        : Icons.account_balance_wallet,
                    color: AppTheme.royalBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      method.methodName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 10),
              Text('Account Title: ${method.accountTitle}'),
              const SizedBox(height: 4),
              Text('Account Number/IBAN: ${method.accountNumber}'),
              if (method.bankId.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Bank ID: ${method.bankId}'),
              ],
              if (method.societyName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Society: ${method.societyName}'),
              ],
              if (method.methodName.toLowerCase().contains('bank')) ...[
                const SizedBox(height: 4),
                Text(
                  'IBAN: ${method.accountNumber.startsWith('PK') ? method.accountNumber : 'N/A'}',
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'User: ${_firebaseUser?.displayName ?? 'Client'}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                'Phone: ${_firebaseUser?.phoneNumber ?? 'Not Available'}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        _copyText(method.accountNumber, 'Account number'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Number'),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _copyText(_formatAmount(widget.amount), 'Amount'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Amount'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedChannelSummary(PaymentMethodModel? method) {
    if (method == null) return const SizedBox.shrink();

    final badgeColor = _mode == PaymentFlowMode.online
        ? Colors.green
        : AppTheme.royalBlue;

    return Container(
      key: ValueKey('${_mode.name}_${method.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badgeColor.withValues(alpha: 0.16), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: badgeColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selected: ${method.methodName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${method.accountTitle} • ${method.accountNumber}',
            style: const TextStyle(fontSize: 12),
          ),
          if (method.bankId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Bank ID: ${method.bankId}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    _copyText(method.accountNumber, 'Account number'),
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy Account'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    _copyText(_formatAmount(widget.amount), 'Amount'),
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy Amount'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaggeredSection({required int order, required Widget child}) {
    final begin = (order * 0.11).clamp(0.0, 0.75);
    final end = (begin + 0.3).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _fadeController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(animation),
        child: child,
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
          'Payment Transaction',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -90,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.lightBlue.withValues(alpha: 0.26),
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStaggeredSection(order: 0, child: _buildStepIndicator()),
                const SizedBox(height: 16),
                _buildStaggeredSection(
                  order: 1,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.royalBlue.withValues(alpha: 0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Hero(
                              tag:
                                  widget.heroTag ??
                                  'payment-hero-${widget.propertyId}',
                              child: Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.propertyName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_installmentTitle Amount: ${_formatAmount(widget.amount)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.hasVoucher) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Voucher downloaded. Use one account below to pay and upload proof.',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildStaggeredSection(
                  order: 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.lightShadow,
                    ),
                    child: SegmentedButton<PaymentFlowMode>(
                      segments: const [
                        ButtonSegment<PaymentFlowMode>(
                          value: PaymentFlowMode.online,
                          icon: Icon(Icons.language),
                          label: Text('Pay Online'),
                        ),
                        ButtonSegment<PaymentFlowMode>(
                          value: PaymentFlowMode.manual,
                          icon: Icon(Icons.account_balance),
                          label: Text('Pay Manually'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (value) {
                        setState(() {
                          _mode = value.first;
                          _selectedMethod = null;
                          _hasSentMoney = false;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildStaggeredSection(
                  order: 3,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          AppTheme.lightBlue.withValues(alpha: 0.65),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.royalBlue.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Text(
                      'Instructions:\n1) Select payment mode and channel.\n2) Check the Bank ID and Society name before paying.\n3) Send the currently due installment and tick confirmation.\n4) Upload paid receipt screenshot.\n5) Submit for admin verification.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildStaggeredSection(
                  order: 4,
                  child: Text(
                    _mode == PaymentFlowMode.online
                        ? 'Online Payment Channels'
                        : 'Manual Bank Payment',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildStaggeredSection(
                  order: 5,
                  child: StreamBuilder<List<PaymentMethodModel>>(
                    stream: _paymentService.getActivePaymentMethods(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Could not load payment methods.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${snapshot.error}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }
                      final methods = snapshot.data ?? [];
                      if (methods.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'No active payment methods available right now.',
                          ),
                        );
                      }

                      _selectedMethod ??= methods.first;

                      Widget modeSpecificActionBar() {
                        if (_mode == PaymentFlowMode.manual) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _downloadChallan,
                                  icon: const Icon(
                                    Icons.download,
                                    color: Colors.white,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.royalBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  label: Text(
                                    _challanDownloaded
                                        ? 'Challan Downloaded'
                                        : 'Download Challan',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Manual Payment Guide:\n1) Download the challan.\n2) Confirm the Bank ID and Society name.\n3) Pay the exact installment amount.\n4) Upload the receipt screenshot after deposit.',
                                  style: TextStyle(fontSize: 11, height: 1.4),
                                ),
                              ),
                            ],
                          );
                        }

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Select an online channel below, copy details, pay, and upload proof.',
                            style: TextStyle(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, animation) {
                              final offsetAnimation = Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              key: ValueKey('mode_${_mode.name}'),
                              child: modeSpecificActionBar(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_isOnlineMode) ...[
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: methods
                                    .map(
                                      (m) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: ChoiceChip(
                                          avatar: _selectedMethod?.id == m.id
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                )
                                              : null,
                                          label: Text(m.methodName),
                                          selected: _selectedMethod?.id == m.id,
                                          onSelected: (_) {
                                            setState(() {
                                              _selectedMethod = m;
                                            });
                                          },
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SizeTransition(
                                    sizeFactor: animation,
                                    axisAlignment: -1,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildSelectedChannelSummary(
                                _selectedMethod,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(
                                      begin: 0.98,
                                      end: 1,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _selectedMethod == null
                                  ? const SizedBox.shrink()
                                  : _buildMethodCard(_selectedMethod!),
                            ),
                            const SizedBox(height: 8),
                          ],
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _hasSentMoney,
                            onChanged: (value) {
                              setState(() => _hasSentMoney = value ?? false);
                            },
                            title: Text(
                              _mode == PaymentFlowMode.online
                                  ? 'I have sent online payment to selected channel'
                                  : 'I have paid manually to selected bank/account',
                            ),
                            subtitle: const Text(
                              'Complete this step before uploading paid receipt proof.',
                              style: TextStyle(fontSize: 12),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                _buildStaggeredSection(
                  order: 6,
                  child: const Text(
                    'Upload Payment Proof',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                _buildStaggeredSection(
                  order: 7,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.lightShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_proofImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _proofImage!,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Center(
                              child: Text('No screenshot selected.'),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width: 160,
                              child: OutlinedButton.icon(
                                onPressed: (_isUploading || !_canUploadProof)
                                    ? null
                                    : _showPickOptions,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Choose Image'),
                              ),
                            ),
                            SizedBox(
                              width: 160,
                              child: ElevatedButton.icon(
                                onPressed:
                                    (_proofImage == null ||
                                        _isUploading ||
                                        !_canUploadProof)
                                    ? null
                                    : _uploadProof,
                                icon: _isUploading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.cloud_upload),
                                label: const Text('Upload Proof'),
                                style: AppTheme.primaryButtonStyle,
                              ),
                            ),
                          ],
                        ),
                        if (_isUploading) ...[
                          const SizedBox(height: 10),
                          LinearProgressIndicator(value: _uploadProgress),
                          const SizedBox(height: 4),
                          Text(
                            '${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded',
                          ),
                        ],
                        AnimatedScale(
                          scale: _uploadedProofUrl != null ? 1 : 0.92,
                          duration: const Duration(milliseconds: 220),
                          child: _uploadedProofUrl != null
                              ? const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text('Proof uploaded'),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildStaggeredSection(
                  order: 8,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitManualPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

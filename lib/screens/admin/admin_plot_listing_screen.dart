import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/plot_model.dart';
import '../../services/plot_service.dart';
import 'admin_drawer.dart';

/// Admin Plot Listing Screen - Add and manage plots
class AdminPlotListingScreen extends StatefulWidget {
  const AdminPlotListingScreen({super.key});

  @override
  State<AdminPlotListingScreen> createState() => _AdminPlotListingScreenState();
}

class _AdminPlotListingScreenState extends State<AdminPlotListingScreen> {
  final PlotService _plotService = PlotService();
  String? _selectedSociety;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        title: const Text(
          'Plot Listing',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          _buildSocietySelector(),
          Expanded(
            child: _selectedSociety == null
                ? _buildSelectSocietyMessage()
                : _buildPlotsList(),
          ),
        ],
      ),
      floatingActionButton: _selectedSociety != null
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.royalBlue,
              onPressed: () => _showAddPlotDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Plot',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildSocietySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Society',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.societies.map((society) {
              final isSelected = _selectedSociety == society;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _selectedSociety = society),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.royalBlue : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.royalBlue
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Text(
                    society,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.primaryTextColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectSocietyMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Select a society to view and manage plots',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPlotsList() {
    return StreamBuilder<List<PlotModel>>(
      stream: _plotService.getPlotsBySociety(_selectedSociety!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final plots = snapshot.data ?? [];

        if (plots.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.landscape_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No plots in $_selectedSociety',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to add a new plot',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plots.length,
          itemBuilder: (context, index) => _buildPlotCard(plots[index]),
        );
      },
    );
  }

  Widget _buildPlotCard(PlotModel plot) {
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
                Expanded(
                  child: Text(
                    plot.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handlePlotAction(value, plot),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    if (plot.status == 'available')
                      const PopupMenuItem(
                        value: 'sell',
                        child: Text('Mark as Sold'),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(plot.size, Icons.square_foot),
                _buildChip(plot.plotType, Icons.category),
                _buildChip('Block ${plot.blockName}', Icons.grid_view),
                _buildChip('Plot ${plot.plotNumber}', Icons.pin_drop),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plot.location,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plot.formattedPrice,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.royalBlue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: plot.status == 'sold'
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    plot.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: plot.status == 'sold' ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.royalBlue),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.royalBlue),
          ),
        ],
      ),
    );
  }

  void _handlePlotAction(String action, PlotModel plot) {
    switch (action) {
      case 'edit':
        _showAddPlotDialog(editPlot: plot);
        break;
      case 'delete':
        _showDeleteConfirmation(plot);
        break;
      case 'sell':
        _showSellPlotDialog(plot);
        break;
    }
  }

  void _showDeleteConfirmation(PlotModel plot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Plot'),
        content: Text('Are you sure you want to delete "${plot.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _plotService.deletePlot(plot.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plot deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSellPlotDialog(PlotModel plot) {
    final ownerNameController = TextEditingController();
    final ownerIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Sold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ownerNameController,
              decoration: AppTheme.inputDecoration(
                hint: 'Enter owner name',
                label: 'Owner Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ownerIdController,
              decoration: AppTheme.inputDecoration(
                hint: 'Enter owner ID/CNIC',
                label: 'Owner ID',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
            ),
            onPressed: () async {
              if (ownerNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter owner name')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _plotService.markPlotAsSold(
                plot.id,
                ownerIdController.text,
                ownerNameController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plot marked as sold')),
                );
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddPlotDialog({PlotModel? editPlot}) {
    final isEditing = editPlot != null;
    final titleController = TextEditingController(text: editPlot?.title ?? '');
    final plotNumberController = TextEditingController(
      text: editPlot?.plotNumber ?? '',
    );
    final blockNameController = TextEditingController(
      text: editPlot?.blockName ?? '',
    );
    final locationController = TextEditingController(
      text: editPlot?.location ?? '',
    );
    final descriptionController = TextEditingController(
      text: editPlot?.description ?? '',
    );
    final priceController = TextEditingController(
      text: editPlot?.price.toString() ?? '',
    );
    final filerPriceController = TextEditingController(
      text: editPlot?.filerPrice?.toString() ?? '',
    );
    final nonFilerPriceController = TextEditingController(
      text: editPlot?.nonFilerPrice?.toString() ?? '',
    );

    String selectedSize = editPlot?.size ?? AppConstants.plotSizes.first;
    String selectedType = editPlot?.plotType ?? AppConstants.plotTypes.first;

    double? parsePrice(String raw) {
      final sanitized = raw.trim().replaceAll(RegExp(r'[^0-9.\-]'), '');
      if (sanitized.isEmpty) return null;
      return double.tryParse(sanitized);
    }

    bool showRequiredError = false;

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
                      Text(
                        isEditing ? 'Edit Plot' : 'Add New Plot',
                        style: const TextStyle(
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
                  Text(
                    'Society: $_selectedSociety',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  if (showRequiredError)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Text(
                        'Please fill all required fields marked with *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.royalBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Text(
                        'All fields marked with * are required.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: AppTheme.inputDecoration(
                      hint: 'e.g., 5 Marla Residential Plot',
                      label: 'Plot Title *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: plotNumberController,
                          decoration: AppTheme.inputDecoration(
                            hint: 'e.g., 123',
                            label: 'Plot Number *',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: blockNameController,
                          decoration: AppTheme.inputDecoration(
                            hint: 'e.g., A, B, C',
                            label: 'Block Name *',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedSize,
                          decoration: AppTheme.inputDecoration(
                            hint: 'Select Size',
                            label: 'Size *',
                          ),
                          items: AppConstants.plotSizes
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => selectedSize = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          decoration: AppTheme.inputDecoration(
                            hint: 'Select Type',
                            label: 'Type *',
                          ),
                          items: AppConstants.plotTypes
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => selectedType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: AppTheme.inputDecoration(
                      hint: 'e.g., 5000000',
                      label: 'Price (PKR) *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: filerPriceController,
                          keyboardType: TextInputType.number,
                          decoration: AppTheme.inputDecoration(
                            hint: 'e.g., 5800000',
                            label: 'Filer Price (PKR) *',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: nonFilerPriceController,
                          keyboardType: TextInputType.number,
                          decoration: AppTheme.inputDecoration(
                            hint: 'e.g., 6200000',
                            label: 'Non-Filer Price (PKR) *',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: AppTheme.inputDecoration(
                      hint: 'e.g., Near Central Park',
                      label: 'Location Details *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: AppTheme.inputDecoration(
                      hint: 'Enter plot description...',
                      label: 'Description *',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: AppTheme.primaryButtonStyle,
                      onPressed: () async {
                        final priceValue = parsePrice(priceController.text);
                        final filerValue = parsePrice(
                          filerPriceController.text,
                        );
                        final nonFilerValue = parsePrice(
                          nonFilerPriceController.text,
                        );

                        if (titleController.text.isEmpty ||
                            plotNumberController.text.isEmpty ||
                            blockNameController.text.isEmpty ||
                            locationController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            priceValue == null ||
                            filerValue == null ||
                            nonFilerValue == null) {
                          setModalState(() => showRequiredError = true);
                          return;
                        }

                        if (showRequiredError) {
                          setModalState(() => showRequiredError = false);
                        }

                        final plot = PlotModel(
                          id: editPlot?.id ?? '',
                          title: titleController.text,
                          society: _selectedSociety!,
                          size: selectedSize,
                          plotNumber: plotNumberController.text,
                          blockName: blockNameController.text,
                          plotType: selectedType,
                          price: priceValue,
                          filerPrice: filerValue,
                          nonFilerPrice: nonFilerValue,
                          location: locationController.text,
                          description: descriptionController.text,
                          status: editPlot?.status ?? 'available',
                        );

                        Navigator.pop(ctx);

                        if (isEditing) {
                          await _plotService.updatePlot(plot);
                        } else {
                          await _plotService.addPlot(plot);
                        }

                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'Plot updated successfully'
                                  : 'Plot added successfully',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        isEditing ? 'Update Plot' : 'Add Plot',
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

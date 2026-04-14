import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/plot_model.dart';
import '../../services/plot_service.dart';

/// Admin Society Details Screen - Shows plot statistics for a specific society
class AdminSocietyDetailsScreen extends StatefulWidget {
  final String societyName;

  const AdminSocietyDetailsScreen({super.key, required this.societyName});

  @override
  State<AdminSocietyDetailsScreen> createState() =>
      _AdminSocietyDetailsScreenState();
}

class _AdminSocietyDetailsScreenState extends State<AdminSocietyDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PlotService _plotService = PlotService();

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
        title: Text(
          widget.societyName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Plots'),
            Tab(text: 'Sold'),
            Tab(text: 'Available'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlotsList(null),
          _buildPlotsList('sold'),
          _buildPlotsList('available'),
        ],
      ),
    );
  }

  Widget _buildPlotsList(String? filterStatus) {
    return StreamBuilder<List<PlotModel>>(
      stream: _plotService.getPlotsBySociety(widget.societyName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var plots = snapshot.data ?? [];

        if (filterStatus != null) {
          plots = plots.where((p) => p.status == filterStatus).toList();
        }

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
                  filterStatus == null
                      ? 'No plots in this society'
                      : filterStatus == 'sold'
                      ? 'No sold plots'
                      : 'No available plots',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plots.length,
          itemBuilder: (context, index) {
            final plot = plots[index];
            return _buildPlotCard(plot);
          },
        );
      },
    );
  }

  Widget _buildPlotCard(PlotModel plot) {
    final isSold = plot.status == 'sold';

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSold
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isSold ? 'SOLD' : 'AVAILABLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSold ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(Icons.square_foot, plot.size),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.grid_view, 'Plot ${plot.plotNumber}'),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.category, plot.plotType),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${plot.blockName}, ${plot.location}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                if (isSold && plot.ownerName != null)
                  Text(
                    'Owner: ${plot.ownerName}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

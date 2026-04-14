import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import 'admin_drawer.dart';

/// Admin Appointments Screen
class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppointmentService _appointmentService = AppointmentService();

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
          'Appointments',
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
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Rejected'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsList(AppConstants.appointmentPending),
          _buildAppointmentsList(AppConstants.appointmentConfirmed),
          _buildAppointmentsList(AppConstants.appointmentRejected),
          _buildAppointmentsList(AppConstants.appointmentCompleted),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(String status) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _appointmentService.getAppointmentsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No $status appointments',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) =>
              _buildAppointmentCard(appointments[index]),
        );
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.royalBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppTheme.royalBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        appointment.purpose,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(appointment.status),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: AppTheme.royalBlue,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.formattedDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          appointment.dayName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: AppTheme.royalBlue,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.timeSlot,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'Time Slot',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  appointment.clientPhone,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.email, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    appointment.clientEmail,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (appointment.plotDetails != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.landscape, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Plot: ${appointment.plotDetails}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
            if (appointment.adminNote != null) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${appointment.adminNote}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (appointment.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Rejection Reason: ${appointment.rejectionReason}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (appointment.status == AppConstants.appointmentPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _showRejectDialog(appointment),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: AppTheme.primaryButtonStyle,
                      onPressed: () => _confirmAppointment(appointment),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            if (appointment.status == AppConstants.appointmentConfirmed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () => _completeAppointment(appointment),
                  child: const Text(
                    'Mark as Completed',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
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
      case AppConstants.appointmentPending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case AppConstants.appointmentConfirmed:
        color = Colors.green;
        label = 'Confirmed';
        break;
      case AppConstants.appointmentRejected:
        color = Colors.red;
        label = 'Rejected';
        break;
      case AppConstants.appointmentCompleted:
        color = Colors.blue;
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

  Future<void> _confirmAppointment(AppointmentModel appointment) async {
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm appointment for ${appointment.clientName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: AppTheme.inputDecoration(
                hint: 'Optional note for the client',
                label: 'Note',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _appointmentService.confirmAppointment(
        appointment.id,
        adminNote: noteController.text.isNotEmpty ? noteController.text : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment confirmed and client notified'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  void _showRejectDialog(AppointmentModel appointment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject appointment for ${appointment.clientName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: AppTheme.inputDecoration(
                hint: 'Reason for rejection (required)',
                label: 'Reason',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _appointmentService.rejectAppointment(
                appointment.id,
                reasonController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment rejected and client notified'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeAppointment(AppointmentModel appointment) async {
    await _appointmentService.completeAppointment(appointment.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment marked as completed'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import 'client_drawer.dart';

/// Client Appointments Screen
class ClientAppointmentsScreen extends StatefulWidget {
  const ClientAppointmentsScreen({super.key});

  @override
  State<ClientAppointmentsScreen> createState() =>
      _ClientAppointmentsScreenState();
}

class _ClientAppointmentsScreenState extends State<ClientAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppointmentService _appointmentService = AppointmentService();
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get userName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Client';
  String get userEmail => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args?['openNew'] == true) {
        _showBookAppointmentDialog(purpose: args?['purpose']);
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
          'My Appointments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      drawer: const ClientDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.royalBlue,
        onPressed: () => _showBookAppointmentDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Book Appointment',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsList('upcoming'),
          _buildAppointmentsList('completed'),
          _buildAppointmentsList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(String type) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _appointmentService.getClientAppointments(userId, type),
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
                  type == 'upcoming'
                      ? 'No upcoming appointments'
                      : type == 'completed'
                      ? 'No completed appointments'
                      : 'No cancelled appointments',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                if (type == 'upcoming') ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: () => _showBookAppointmentDialog(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Book Appointment',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        boxShadow: AppTheme.lightShadow,
      ),
      child: Column(
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.mediumRadius),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appointment.appointmentDate.day.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.dayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        appointment.formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(appointment.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color: AppTheme.royalBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appointment.timeSlot,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Purpose: ${appointment.purpose}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (appointment.plotDetails != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.landscape, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Plot: ${appointment.plotDetails}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
                if (appointment.adminNote != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.note, size: 14, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Note: ${appointment.adminNote}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (appointment.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, size: 14, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reason: ${appointment.rejectionReason}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (appointment.status == AppConstants.appointmentPending) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _cancelAppointment(appointment),
                      child: const Text('Cancel Appointment'),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.appointmentPending:
        return Colors.orange;
      case AppConstants.appointmentConfirmed:
        return Colors.green;
      case AppConstants.appointmentRejected:
        return Colors.red;
      case AppConstants.appointmentCompleted:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _appointmentService.cancelAppointment(appointment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showBookAppointmentDialog({String? purpose}) {
    final purposeController = TextEditingController(text: purpose);
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTimeSlot = '10:00 AM - 11:00 AM';

    final timeSlots = [
      '10:00 AM - 11:00 AM',
      '11:00 AM - 12:00 PM',
      '12:00 PM - 01:00 PM',
      '02:00 PM - 03:00 PM',
      '03:00 PM - 04:00 PM',
      '04:00 PM - 05:00 PM',
    ];

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Book Appointment',
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
                TextField(
                  controller: purposeController,
                  decoration: AppTheme.inputDecoration(
                    hint: 'Enter purpose of visit',
                    label: 'Purpose',
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (date != null) {
                      setModalState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppTheme.royalBlue,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Date',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedTimeSlot,
                  decoration: AppTheme.inputDecoration(
                    hint: 'Select time slot',
                    label: 'Time Slot',
                  ),
                  items: timeSlots
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedTimeSlot = v!),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (purposeController.text.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please enter purpose of visit'),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(ctx);

                      final appointment = AppointmentModel(
                        id: '',
                        clientId: userId,
                        clientName: userName,
                        clientEmail: userEmail,
                        clientPhone: '',
                        appointmentDate: selectedDate,
                        timeSlot: selectedTimeSlot,
                        purpose: purposeController.text,
                        status: AppConstants.appointmentPending,
                        createdAt: DateTime.now(),
                      );

                      await _appointmentService.bookAppointment(appointment);

                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Appointment requested successfully'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    },
                    child: const Text(
                      'Book Appointment',
                      style: AppTheme.buttonText,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// App-wide constants for RoyalNest application.
// This file contains hardcoded values that can be changed easily.
library;

class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ============== ADMIN CREDENTIALS ==============
  // Change these values to update admin login credentials
  static const String adminEmail = 'admin17@gmail.com';
  static const String adminPassword = 'admin1234';

  // ============== SOCIETIES ==============
  static const List<String> societies = [
    'Royal Smart City',
    'Royal City',
    'Royal Homes',
  ];

  // ============== PLOT SIZES ==============
  static const List<String> plotSizes = [
    '3 Marla',
    '5 Marla',
    '7 Marla',
    '8 Marla',
    '10 Marla',
    '1 Kanal',
    '2 Kanal',
  ];

  // ============== PLOT TYPES ==============
  static const List<String> plotTypes = ['Residential', 'Commercial'];

  // ============== PAYMENT STATUS ==============
  static const String paymentPaid = 'paid';
  static const String paymentUnpaid = 'unpaid';
  static const String paymentPartial = 'partial';

  // ============== QUERY STATUS ==============
  static const String queryPending = 'pending';
  static const String queryInProgress = 'in_progress';
  static const String queryCompleted = 'completed';

  // ============== APPOINTMENT STATUS ==============
  static const String appointmentPending = 'pending';
  static const String appointmentConfirmed = 'confirmed';
  static const String appointmentRejected = 'rejected';
  static const String appointmentCompleted = 'completed';
  static const String appointmentCancelled = 'cancelled';

  // ============== DOCUMENT STATUS ==============
  static const String documentPending = 'pending';
  // New canonical status for admin decisions.
  static const String documentApproved = 'approved';
  // Backward compatibility for older documents and UI paths.
  static const String documentVerified = 'verified';
  static const String documentRejected = 'rejected';

  // ============== LOST & FOUND STATUS ==============
  static const String itemLost = 'lost';
  static const String itemFound = 'found';
  static const String itemActive = 'active';
  static const String itemClaimed = 'claimed';
  static const String itemResolved = 'resolved';
  static const String itemReturned = 'returned';

  // ============== LOST & FOUND CLAIM STATUS ==============
  static const String claimPending = 'pending';
  static const String claimApproved = 'approved';
  static const String claimRejected = 'rejected';

  // ============== USER ROLES ==============
  static const String roleAdmin = 'admin';
  static const String roleClient = 'client';

  // ============== FILER/NON-FILER PLANS ==============
  static const Map<String, dynamic> filerPlan = {
    'booking': '10%',
    'confirmation': '15%',
    'months': 36,
  };

  static const Map<String, dynamic> nonFilerPlan = {
    'booking': '15%',
    'confirmation': '20%',
    'months': 30,
  };

  // ============== CLOUDINARY (UNSIGNED UPLOAD) ==============
  // Set these values from your Cloudinary dashboard.
  static const String cloudinaryCloudName = 'dncjcwexo';
  static const String cloudinaryUploadPreset = 'royalnest';
}

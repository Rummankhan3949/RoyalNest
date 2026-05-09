import 'package:flutter/material.dart';
import 'package:media_store_plus/media_store_plus.dart';

import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/unified_auth_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/admin_plot_listing_screen.dart';
import 'screens/admin/admin_queries_screen.dart';
import 'screens/admin/admin_appointments_screen.dart';
import 'screens/admin/admin_lost_found_screen.dart';
import 'screens/admin/admin_payments_screen.dart';
import 'screens/admin/admin_manual_payments_screen.dart';
import 'screens/admin/admin_payment_methods_screen.dart';
import 'screens/admin/admin_documents_screen.dart';
import 'screens/admin/admin_clients_screen.dart';
import 'screens/admin/admin_events_screen.dart';
import 'screens/admin/admin_ml_prediction_screen.dart';
import 'screens/admin/admin_ai_assistant_screen.dart';
import 'screens/client/client_main_screen.dart';
import 'screens/client/client_home_screen.dart';
import 'screens/client/client_dashboard_screen.dart';
import 'screens/client/client_plots_screen.dart';
import 'screens/client/client_queries_screen.dart';
import 'screens/client/client_appointments_screen.dart';
import 'screens/client/client_payments_screen.dart';
import 'screens/client/client_manual_payments_screen.dart';
import 'screens/client/client_manual_payment_receipt_screen.dart';
import 'screens/client/client_lost_found_screen.dart';
import 'screens/client/client_documents_screen.dart';
import 'screens/client/client_notifications_screen.dart';
import 'screens/client/client_profile_screen.dart';
import 'screens/client/client_ai_assistant_screen.dart';

/// INSTANT APP LAUNCH - Splash screen appears immediately
/// All heavy initialization (Firebase, etc.) happens AFTER splash displays
Future<void> main() async {
  // Keep startup predictable; this is fast and ensures plugins bind correctly.
  WidgetsFlutterBinding.ensureInitialized();
  await MediaStore.ensureInitialized();
  MediaStore.appFolder = 'RoyalNest';
  runApp(const RoyalNestApp());
}

class RoyalNestApp extends StatelessWidget {
  const RoyalNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Royal Nest',
      theme: AppTheme.lightTheme,
      themeAnimationCurve: Curves.easeInOutCubic,
      themeAnimationDuration: const Duration(milliseconds: 320),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final width = mediaQuery.size.width;
        final effectiveChild = child ?? const SizedBox.shrink();

        final appBody = width >= 900
            ? Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: effectiveChild,
                ),
              )
            : effectiveChild;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              mediaQuery.textScaler.scale(1).clamp(0.9, 1.15),
            ),
          ),
          child: appBody,
        );
      },
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const UnifiedAuthScreen(),
        '/verify-email': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final email = args is Map<String, dynamic>
              ? args['email']?.toString()
              : null;
          return EmailVerificationScreen(prefilledEmail: email);
        },
        // Admin routes
        '/admin-home': (context) => const AdminHomeScreen(),
        '/admin-plots': (context) => const AdminPlotListingScreen(),
        '/admin-queries': (context) => const AdminQueriesScreen(),
        '/admin-appointments': (context) => const AdminAppointmentsScreen(),
        '/admin-lost-found': (context) => const AdminLostFoundScreen(),
        '/admin-payments': (context) => const AdminPaymentsScreen(),
        '/admin-manual-payments': (context) =>
            const AdminManualPaymentsScreen(),
        '/admin-payment-methods': (context) =>
            const AdminPaymentMethodsScreen(),
        '/admin-documents': (context) => const AdminDocumentsScreen(),
        '/admin-clients': (context) => const AdminClientsScreen(),
        '/admin-events': (context) => const AdminEventsScreen(),
        '/admin-ml-prediction': (context) => const AdminMLPredictionScreen(),
        '/admin-ai-assistant': (context) => const AdminAIAssistantScreen(),
        // Client routes
        '/client-main': (context) => const ClientMainScreen(),
        '/client-home': (context) => const ClientHomeScreen(),
        '/client-dashboard': (context) => const ClientDashboardScreen(),
        '/client-plots': (context) => const ClientPlotsScreen(),
        '/client-queries': (context) => const ClientQueriesScreen(),
        '/client-appointments': (context) => const ClientAppointmentsScreen(),
        '/client-payments': (context) => const ClientPaymentsScreen(),
        '/client-manual-payments': (context) =>
            const ClientManualPaymentsScreen(),
        '/client-lost-found': (context) => const ClientLostFoundScreen(),
        '/client-documents': (context) => const ClientDocumentsScreen(),
        '/client-notifications': (context) => const ClientNotificationsScreen(),
        '/client-profile': (context) => const ClientProfileScreen(),
        '/client-ai-assistant': (context) => const ClientAIAssistantScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/client-manual-payment-receipt') {
          final paymentId = settings.arguments as String?;
          if (paymentId != null && paymentId.isNotEmpty) {
            return MaterialPageRoute(
              builder: (_) =>
                  ClientManualPaymentReceiptScreen(paymentId: paymentId),
            );
          }
        }
        return null;
      },
      initialRoute: '/',
    );
  }
}

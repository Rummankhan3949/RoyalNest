import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/plot_model.dart';
import '../models/payment_model.dart';

/// Service for client management
class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';
  final String _plotsCollection = 'plots';
  final String _paymentsCollection = 'payments';

  /// Get all clients
  Stream<List<UserModel>> getAllClients() {
    return _firestore
        .collection(_usersCollection)
        .where('role', isEqualTo: 'client')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final raw = Map<String, dynamic>.from(doc.data());
                raw['uid'] = (raw['uid'] ?? '').toString().trim().isNotEmpty
                    ? raw['uid']
                    : doc.id;
                return UserModel.fromMap(raw);
              })
              .where(
                (client) =>
                    client.uid.trim().isNotEmpty &&
                    client.email.trim().isNotEmpty,
              )
              .toList();
        });
  }

  /// Get client by ID
  Future<UserModel?> getClientById(String clientId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(clientId)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Alias used by UI
  Future<UserModel?> getClientProfile(String clientId) {
    return getClientById(clientId);
  }

  /// Get client's plots
  Future<List<PlotModel>> getClientPlots(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection(_plotsCollection)
          .where('ownerId', isEqualTo: clientId)
          .get();

      return snapshot.docs
          .map((doc) => PlotModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get client's payments
  Future<List<PaymentModel>> getClientPayments(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection(_paymentsCollection)
          .where('clientId', isEqualTo: clientId)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get complete client details with plots and payments
  Future<Map<String, dynamic>> getCompleteClientDetails(String clientId) async {
    try {
      final client = await getClientById(clientId);
      final plots = await getClientPlots(clientId);
      final payments = await getClientPayments(clientId);

      double totalAmount = 0;
      double paidAmount = 0;
      double remainingAmount = 0;

      for (var payment in payments) {
        totalAmount += payment.totalAmount;
        paidAmount += payment.paidAmount;
        remainingAmount += payment.remainingAmount;
      }

      return {
        'client': client,
        'plots': plots,
        'payments': payments,
        'summary': {
          'totalPlots': plots.length,
          'totalAmount': totalAmount,
          'paidAmount': paidAmount,
          'remainingAmount': remainingAmount,
        },
      };
    } catch (e) {
      return {};
    }
  }

  /// Alias for UI compatibility
  Future<Map<String, dynamic>> getClientDetails(String clientId) {
    return getCompleteClientDetails(clientId);
  }

  /// Update client
  Future<bool> updateClient(UserModel client) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(client.uid)
          .update(client.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get client counts
  Future<Map<String, int>> getClientCounts() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: 'client')
          .get();

      int verified = 0;
      int unverified = 0;
      int filers = 0;
      int nonFilers = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isDocumentsVerified'] == true) {
          verified++;
        } else {
          unverified++;
        }
        if (data['isFiler'] == true) {
          filers++;
        } else {
          nonFilers++;
        }
      }

      return {
        'total': snapshot.docs.length,
        'verified': verified,
        'unverified': unverified,
        'filers': filers,
        'nonFilers': nonFilers,
      };
    } catch (e) {
      return {};
    }
  }

  /// Search clients
  Future<List<UserModel>> searchClients(String query) async {
    try {
      // Search by username or email
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: 'client')
          .get();

      final queryLower = query.toLowerCase();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where(
            (client) =>
                client.username.toLowerCase().contains(queryLower) ||
                client.email.toLowerCase().contains(queryLower) ||
                client.cnic.contains(query),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }
}

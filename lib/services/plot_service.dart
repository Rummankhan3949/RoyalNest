import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/plot_model.dart';

/// Service for plot management operations
class PlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'plots';

  /// Get all plots
  Stream<List<PlotModel>> getAllPlots() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlotModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get plots by society
  Stream<List<PlotModel>> getPlotsBySociety(String society) {
    return _firestore
        .collection(_collection)
        .where('society', isEqualTo: society)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlotModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get available plots
  Stream<List<PlotModel>> getAvailablePlots() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlotModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get plots by status
  Stream<List<PlotModel>> getPlotsByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlotModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get society statistics
  Future<Map<String, int>> getSocietyStats(String society) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('society', isEqualTo: society)
        .get();

    int total = snapshot.docs.length;
    int sold = snapshot.docs
        .where((doc) => doc.data()['status'] == 'sold')
        .length;
    int available = total - sold;

    return {'total': total, 'sold': sold, 'available': available};
  }

  /// Get overall statistics
  Future<Map<String, Map<String, int>>> getAllSocietiesStats() async {
    final societies = ['Royal Smart City', 'Royal City', 'Royal Homes'];
    Map<String, Map<String, int>> stats = {};

    for (var society in societies) {
      stats[society] = await getSocietyStats(society);
    }

    return stats;
  }

  /// Add new plot
  Future<bool> addPlot(PlotModel plot) async {
    try {
      await _firestore.collection(_collection).add(plot.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update plot
  Future<bool> updatePlot(PlotModel plot) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(plot.id)
          .update(plot.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete plot
  Future<bool> deletePlot(String plotId) async {
    try {
      await _firestore.collection(_collection).doc(plotId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark plot as sold
  Future<bool> markPlotAsSold(
    String plotId,
    String ownerId,
    String ownerName,
  ) async {
    try {
      await _firestore.collection(_collection).doc(plotId).update({
        'status': 'sold',
        'ownerId': ownerId,
        'ownerName': ownerName,
        'soldAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get client's plots
  Stream<List<PlotModel>> getClientPlots(String clientId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: clientId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlotModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Count client's plots
  Future<int> getClientPlotsCount(String clientId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: clientId)
        .get();
    return snapshot.docs.length;
  }
}

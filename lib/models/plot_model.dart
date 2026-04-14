import 'package:cloud_firestore/cloud_firestore.dart';

/// Plot model representing a plot in any society
class PlotModel {
  final String id;
  final String title;
  final String society;
  final String size;
  final String plotNumber;
  final String blockName;
  final String
  plotType; // Residential, Commercial, Corner, Park Facing, Boulevard
  final double price;
  final String location;
  final String description;
  final String status; // available, sold, reserved
  final String? ownerId; // Client ID who owns/bought the plot
  final String? ownerName;
  final DateTime? createdAt;
  final DateTime? soldAt;

  const PlotModel({
    required this.id,
    required this.title,
    required this.society,
    required this.size,
    required this.plotNumber,
    required this.blockName,
    required this.plotType,
    required this.price,
    required this.location,
    required this.description,
    this.status = 'available',
    this.ownerId,
    this.ownerName,
    this.createdAt,
    this.soldAt,
  });

  String get formattedPrice {
    if (price >= 10000000) {
      return 'PKR ${(price / 10000000).toStringAsFixed(2)} Crore';
    } else if (price >= 100000) {
      return 'PKR ${(price / 100000).toStringAsFixed(2)} Lac';
    } else {
      return 'PKR ${price.toStringAsFixed(0)}';
    }
  }

  factory PlotModel.fromMap(Map<String, dynamic> map, String docId) {
    return PlotModel(
      id: docId,
      title: map['title'] ?? '',
      society: map['society'] ?? '',
      size: map['size'] ?? '',
      plotNumber: map['plotNumber'] ?? '',
      blockName: map['blockName'] ?? '',
      plotType: map['plotType'] ?? 'Residential',
      price: (map['price'] ?? 0).toDouble(),
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'available',
      ownerId: map['ownerId'],
      ownerName: map['ownerName'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      soldAt: (map['soldAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'society': society,
      'size': size,
      'plotNumber': plotNumber,
      'blockName': blockName,
      'plotType': plotType,
      'price': price,
      'location': location,
      'description': description,
      'status': status,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'soldAt': soldAt != null ? Timestamp.fromDate(soldAt!) : null,
    };
  }

  PlotModel copyWith({
    String? id,
    String? title,
    String? society,
    String? size,
    String? plotNumber,
    String? blockName,
    String? plotType,
    double? price,
    String? location,
    String? description,
    String? status,
    String? ownerId,
    String? ownerName,
    DateTime? createdAt,
    DateTime? soldAt,
  }) {
    return PlotModel(
      id: id ?? this.id,
      title: title ?? this.title,
      society: society ?? this.society,
      size: size ?? this.size,
      plotNumber: plotNumber ?? this.plotNumber,
      blockName: blockName ?? this.blockName,
      plotType: plotType ?? this.plotType,
      price: price ?? this.price,
      location: location ?? this.location,
      description: description ?? this.description,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt ?? this.createdAt,
      soldAt: soldAt ?? this.soldAt,
    );
  }
}

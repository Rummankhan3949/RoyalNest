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
  final double? filerPrice;
  final double? nonFilerPrice;
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
    this.filerPrice,
    this.nonFilerPrice,
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
    double? readNullablePrice(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      final sanitized = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
      if (sanitized.isEmpty) return null;
      return double.tryParse(sanitized);
    }

    return PlotModel(
      id: docId,
      title: map['title'] ?? '',
      society: map['society'] ?? '',
      size: map['size'] ?? '',
      plotNumber: map['plotNumber'] ?? '',
      blockName: map['blockName'] ?? '',
      plotType: map['plotType'] ?? 'Residential',
      price: (map['price'] ?? 0).toDouble(),
      filerPrice: readNullablePrice(map['filerPrice'] ?? map['filer_price']),
      nonFilerPrice: readNullablePrice(
        map['nonFilerPrice'] ?? map['non_filer_price'],
      ),
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
      'filerPrice': filerPrice,
      'nonFilerPrice': nonFilerPrice,
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
    double? filerPrice,
    double? nonFilerPrice,
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
      filerPrice: filerPrice ?? this.filerPrice,
      nonFilerPrice: nonFilerPrice ?? this.nonFilerPrice,
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

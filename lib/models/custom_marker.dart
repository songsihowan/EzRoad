import 'dart:convert';

class CustomMarker {
  final String id;
  final double lat;
  final double lng;
  final String name;
  final String description;
  final String colorHex;
  final String icon;
  final String imageUrl;
  final String videoUrl;
  final String mediaType;
  final String category;
  final String transport;
  final DateTime createdAt;

  CustomMarker({
    required this.id,
    required this.lat,
    required this.lng,
    required this.name,
    this.description = '',
    this.colorHex = '#FF6B6B',
    this.icon = '⚠️',
    this.imageUrl = '',
    this.videoUrl = '',
    this.mediaType = 'image',
    this.category = '',
    this.transport = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': lat,
    'lng': lng,
    'name': name,
    'description': description,
    'colorHex': colorHex,
    'icon': icon,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'mediaType': mediaType,
    'category': category,
    'transport': transport,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CustomMarker.fromJson(Map<String, dynamic> json) => CustomMarker(
    id: json['id'],
    lat: json['lat'],
    lng: json['lng'],
    name: json['name'],
    description: json['description'] ?? '',
    colorHex: json['colorHex'] ?? '#FF6B6B',
    icon: json['icon'] ?? '⚠️',
    imageUrl: json['imageUrl'] ?? '',
    videoUrl: json['videoUrl'] ?? '',
    mediaType: json['mediaType'] ?? 'image',
    category: json['category'] ?? '',
    transport: json['transport'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
  );

  static List<CustomMarker> listFromJson(String jsonStr) {
    final List decoded = jsonDecode(jsonStr);
    return decoded.map((e) => CustomMarker.fromJson(e)).toList();
  }

  static String listToJson(List<CustomMarker> markers) {
    return jsonEncode(markers.map((m) => m.toJson()).toList());
  }

  CustomMarker copyWith({
    String? name,
    String? description,
    String? colorHex,
    String? icon,
    String? imageUrl,
    String? videoUrl,
    String? mediaType,
    String? category,
    String? transport,
  }) => CustomMarker(
    id: id,
    lat: lat,
    lng: lng,
    name: name ?? this.name,
    description: description ?? this.description,
    colorHex: colorHex ?? this.colorHex,
    icon: icon ?? this.icon,
    imageUrl: imageUrl ?? this.imageUrl,
    videoUrl: videoUrl ?? this.videoUrl,
    mediaType: mediaType ?? this.mediaType,
    category: category ?? this.category,
    transport: transport ?? this.transport,
    createdAt: createdAt,
  );
}
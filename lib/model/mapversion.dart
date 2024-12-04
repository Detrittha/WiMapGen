import 'dart:convert';

class Heatmap {
  final int versionId;
  final int mapId;
  final DateTime createdAt;
  final String versionDescription;
  final double maxDbm;
  final double minDbm;
  final String image;
  final int userId;
  final String userFirstName;
  final String userLastName;
  final String mapName;
   final String mapLocation;
  final String ssid; // เพิ่มฟิลด์ ssid
  final String bssid; // เพิ่มฟิลด์ bssid
  final int frequency; // เพิ่มฟิลด์ frequency

  Heatmap({
    required this.versionId,
    required this.mapId,
    required this.createdAt,
    required this.versionDescription,
    required this.maxDbm,
    required this.minDbm,
    required this.image,
    required this.userId,
    required this.userFirstName,
    required this.userLastName,
    required this.mapName,
    required this.mapLocation,
    required this.ssid,
    required this.bssid,
    required this.frequency,
  });

  // Factory method to create a Heatmap instance from JSON
  factory Heatmap.fromJson(Map<String, dynamic> json) {
    return Heatmap(
      versionId: json['version_id'] ?? 0,
      mapId: json['map_id'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      versionDescription: json['version_description'] ?? '',
      maxDbm: json['max_dBm'] != null ? double.parse(json['max_dBm'].toString()) : 0.0,
      minDbm: json['min_dBm'] != null ? double.parse(json['min_dBm'].toString()) : 0.0,
      image: json['image'] ?? '',
      userId: json['user_id'] ?? 0,
      userFirstName: json['user_first_name'] ?? '',
      userLastName: json['user_last_name'] ?? '',
      mapName: json['map_name'] ?? '',
      mapLocation: json['map_location'] ?? '',
      ssid: json['map_ssid'] ?? '', // แปลงค่า ssid
      bssid: json['map_bssid'] ?? '', // แปลงค่า bssid
      frequency: json['map_freq'] != null ? int.parse(json['map_freq'].toString()) : 0, // แปลงค่า frequency
    );
  }

  // Method to convert a Heatmap instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'version_id': versionId,
      'map_id': mapId,
      'created_at': createdAt.toIso8601String(),
      'version_description': versionDescription,
      'max_dBm': maxDbm,
      'min_dBm': minDbm,
      'image': image,
      'user_id': userId,
      'user_first_name': userFirstName,
      'user_last_name': userLastName,
      'map_name': mapName,
      'map_location':mapLocation,
      'map_ssid': ssid, // แปลงค่า ssid
      'map_bssid': bssid, // แปลงค่า bssid
      'map_freq': frequency, // แปลงค่า frequency
    };
  }
}

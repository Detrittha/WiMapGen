class Project {
  final int mapId;
  final int userId;
  final int versionId; // ฟิลด์ใหม่
  final String name;
  final String bssid;
  final String ssid;
  final int frequency;
  final String location;
  final String imageData;
  final String description;
  final String maxDbm;
  final String minDbm;
  final String image;
  final DateTime createdAt;

  Project({
    required this.mapId,
    required this.userId,
    required this.versionId, // ฟิลด์ใหม่
    required this.name,
    required this.bssid,
    required this.ssid,
    required this.frequency,
    required this.location,
    required this.imageData,
    required this.description,
    required this.maxDbm,
    required this.minDbm,
    required this.image,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      mapId: json['Map_id'] ?? 0,
      userId: json['User_id'] ?? 0,
      versionId: json['Version_id'] ?? 0, // ฟิลด์ใหม่
      name: json['name'] ?? '',
      bssid: json['BSSID'] ?? '',
      ssid: json['SSID'] ?? '',
      frequency: json['frequency'] ?? 0,
      location: json['location'] ?? '',
      imageData: json['ImageData']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      maxDbm: json['Max_dBm']?.toString() ?? '',
      minDbm: json['Min_dBm']?.toString() ?? '',
      image: json['Image'] ?? '',
      createdAt: json['Created_at'] != null
          ? DateTime.tryParse(json['Created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

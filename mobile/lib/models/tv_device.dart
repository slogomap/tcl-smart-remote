class TvDevice {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final String? macAddress;
  final String model;
  final String osVersion;
  final bool isPaired;
  final DateTime? lastConnectedAt;

  TvDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    this.port = 6467,
    this.macAddress,
    this.model = 'TCL Google TV',
    this.osVersion = 'Android TV 12',
    this.isPaired = false,
    this.lastConnectedAt,
  });

  TvDevice copyWith({
    String? id,
    String? name,
    String? ipAddress,
    int? port,
    String? macAddress,
    String? model,
    String? osVersion,
    bool? isPaired,
    DateTime? lastConnectedAt,
  }) {
    return TvDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      macAddress: macAddress ?? this.macAddress,
      model: model ?? this.model,
      osVersion: osVersion ?? this.osVersion,
      isPaired: isPaired ?? this.isPaired,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip_address': ipAddress,
      'port': port,
      'mac_address': macAddress,
      'model': model,
      'os_version': osVersion,
      'is_paired': isPaired ? 1 : 0,
      'last_connected_at': lastConnectedAt?.toIso8601String(),
    };
  }

  factory TvDevice.fromJson(Map<String, dynamic> json) {
    return TvDevice(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'TCL TV',
      ipAddress: json['ip_address']?.toString() ?? '',
      port: (json['port'] is int) ? json['port'] : int.tryParse(json['port']?.toString() ?? '6467') ?? 6467,
      macAddress: json['mac_address']?.toString(),
      model: json['model']?.toString() ?? 'TCL Google TV',
      osVersion: json['os_version']?.toString() ?? 'Android TV',
      isPaired: json['is_paired'] == 1 || json['is_paired'] == true,
      lastConnectedAt: json['last_connected_at'] != null
          ? DateTime.tryParse(json['last_connected_at'].toString())
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvDevice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

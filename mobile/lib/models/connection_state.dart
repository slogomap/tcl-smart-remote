enum DeviceConnectionStatus {
  disconnected,
  connecting,
  pairing,
  connected,
  offline,
  error,
}

class RemoteConnectionState {
  final DeviceConnectionStatus status;
  final String? activeDeviceId;
  final String? activeDeviceName;
  final String? activeDeviceIp;
  final String? errorMessage;
  final int? batteryLevel;
  final bool isLocalWifiActive;

  const RemoteConnectionState({
    this.status = DeviceConnectionStatus.disconnected,
    this.activeDeviceId,
    this.activeDeviceName,
    this.activeDeviceIp,
    this.errorMessage,
    this.batteryLevel,
    this.isLocalWifiActive = true,
  });

  bool get isConnected => status == DeviceConnectionStatus.connected;
  bool get isConnecting => status == DeviceConnectionStatus.connecting || status == DeviceConnectionStatus.pairing;
  bool get isDisconnected => status == DeviceConnectionStatus.disconnected || status == DeviceConnectionStatus.offline || status == DeviceConnectionStatus.error;

  RemoteConnectionState copyWith({
    DeviceConnectionStatus? status,
    String? activeDeviceId,
    String? activeDeviceName,
    String? activeDeviceIp,
    String? errorMessage,
    int? batteryLevel,
    bool? isLocalWifiActive,
  }) {
    return RemoteConnectionState(
      status: status ?? this.status,
      activeDeviceId: activeDeviceId ?? this.activeDeviceId,
      activeDeviceName: activeDeviceName ?? this.activeDeviceName,
      activeDeviceIp: activeDeviceIp ?? this.activeDeviceIp,
      errorMessage: errorMessage ?? this.errorMessage,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isLocalWifiActive: isLocalWifiActive ?? this.isLocalWifiActive,
    );
  }
}

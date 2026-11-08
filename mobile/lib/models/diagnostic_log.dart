class DiagnosticLog {
  final String id;
  final String level; // INFO, WARN, ERROR, DEBUG
  final String component;
  final String message;
  final dynamic metadata;
  final DateTime timestamp;

  DiagnosticLog({
    required this.id,
    required this.level,
    required this.component,
    required this.message,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'component': component,
      'message': message,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DiagnosticLog.fromJson(Map<String, dynamic> json) {
    return DiagnosticLog(
      id: json['id']?.toString() ?? '',
      level: json['level']?.toString() ?? 'INFO',
      component: json['component']?.toString() ?? 'General',
      message: json['message']?.toString() ?? '',
      metadata: json['metadata'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

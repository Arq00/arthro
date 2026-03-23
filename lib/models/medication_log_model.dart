class MedicationLog {
  final String id;
  final String medicationId;
  final String medicationName;
  final DateTime timestamp;
  final int doseNumber; // 1 = first dose of the day, 2 = second (Twice Daily)
  final bool wasLate; // true if logged after the 30-min grace window
  final List<String> sideEffectsReported; // side effects noted at log time
  final String? notes; // optional free-text note at log time

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.timestamp,
    required this.doseNumber,
    this.wasLate = false,
    this.sideEffectsReported = const [],
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicationId': medicationId,
      'medicationName': medicationName,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'doseNumber': doseNumber,
      'wasLate': wasLate,
      'sideEffectsReported': sideEffectsReported,
      'notes': notes,
    };
  }

  factory MedicationLog.fromFirestore(String id, Map<String, dynamic> data) {
    return MedicationLog(
      id: id,
      medicationId: data['medicationId'] ?? '',
      medicationName: data['medicationName'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      doseNumber: data['doseNumber'] ?? 1,
      wasLate: data['wasLate'] ?? false,
      sideEffectsReported: List<String>.from(data['sideEffectsReported'] ?? []),
      notes: data['notes'],
    );
  }
}
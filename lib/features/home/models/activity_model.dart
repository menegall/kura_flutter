class Activity {
  final String id;
  final String pupilId;
  final DateTime activityDate;
  final double? duration;
  final String? description;
  final double? kilometers;
  final String type;
  final double? stamp;
  final DateTime createdAt;
  Activity({
    required this.id,
    required this.pupilId,
    required this.activityDate,
    this.duration,
    this.description,
    this.kilometers,
    required this.type,
    this.stamp,
    required this.createdAt,
  });
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      pupilId: json['pupil_id'] as String,
      activityDate: DateTime.parse(json['activity_date'] as String),
      duration: (json['duration'] as num?)?.toDouble(),
      description: json['description'] as String?,
      kilometers: (json['kilometers'] as num?)?.toDouble(),
      type: json['type'] as String,
      stamp: (json['stamp'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  // Metodo per visualizzare il tipo in Italiano
  String get typeLabel {
    switch (type) {
      case 'call':
        return 'Telefonata';
      case 'transfert':
        return 'Trasferta';
      case 'mail':
        return 'Email/Lettera';
      case 'meeting_various':
        return 'Incontro Varie';
      case 'meeting_pupils':
        return 'Incontro con Pupillo';
      case 'other':
      default:
        return 'Altro';
    }
  }
}
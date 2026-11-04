class Pupil {
  final String id;
  final String userId;
  final String name;
  final double maxHours;
  final double workedHours;
  final double tarif;
  final double kmTarif;
  // Data di archiviazione: null se il pupillo è attivo.
  final DateTime? archivedAt;
  Pupil({
    required this.id,
    required this.userId,
    required this.name,
    required this.maxHours,
    required this.workedHours,
    required this.tarif,
    required this.kmTarif,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
  factory Pupil.fromJson(Map<String, dynamic> json) {
    // Somma le ore spese (hours_spent) da tutte le attività collegate nell'anno corrente
    final activitiesList = json['activities'] as List<dynamic>? ?? [];
    double totalWorked = 0.0;
    final currentYear = DateTime.now().year;
    for (var act in activitiesList) {
      final duration = act['duration'];
      final dateStr = act['activity_date'];
      if (duration != null && dateStr != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null && date.year == currentYear) {
          totalWorked += (duration as num).toDouble();
        }
      }
    }
    return Pupil(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      maxHours: (json['max_hours'] as num).toDouble(),
      workedHours: totalWorked,
      tarif: (json['tarif'] as num?)?.toDouble() ?? 0.0,
      kmTarif: (json['km_tarif'] as num?)?.toDouble() ?? 0.0,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
    );
  }
}
import 'package:flutter/material.dart';

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
  final double? otherExpenses;

  Activity({
    required this.id,
    required this.pupilId,
    required this.activityDate,
    this.duration,
    this.description,
    this.kilometers,
    required this.type,
    this.stamp,
    this.otherExpenses,
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
      otherExpenses: (json['other_expenses'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  /// Tipi di attività nell'ordine in cui compaiono nel form.
  static const List<String> types = [
    'call',
    'meeting_pupils',
    'meeting_various',
    'mail',
    'transfert',
    'other',
  ];

  // Metodo per visualizzare il tipo in Italiano
  String get typeLabel => labelFor(type);

  // Icona associata al tipo di attività
  IconData get icon => iconFor(type);

  static String labelFor(String type) {
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

  static IconData iconFor(String type) {
    switch (type) {
      case 'call':
        return Icons.phone_outlined;
      case 'transfert':
        return Icons.directions_car_outlined;
      case 'mail':
        return Icons.email_outlined;
      case 'meeting_various':
        return Icons.groups_outlined;
      case 'meeting_pupils':
        return Icons.person_search_outlined;
      case 'other':
      default:
        return Icons.work_outline;
    }
  }
}

/// Attività di un mese, con il totale delle ore.
class MonthGroup {
  final int year;
  final int month;
  final List<Activity> activities;

  MonthGroup(this.year, this.month, this.activities);

  double get totalHours =>
      activities.fold(0.0, (sum, a) => sum + (a.duration ?? 0));
}

/// Raggruppa per mese attività già ordinate per data, mantenendo l'ordine.
List<MonthGroup> groupActivitiesByMonth(List<Activity> activities) {
  final groups = <MonthGroup>[];
  for (final activity in activities) {
    final date = activity.activityDate;
    final last = groups.isEmpty ? null : groups.last;
    if (last != null && last.year == date.year && last.month == date.month) {
      last.activities.add(activity);
    } else {
      groups.add(MonthGroup(date.year, date.month, [activity]));
    }
  }
  return groups;
}

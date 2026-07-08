import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pupil_model.dart';
import '../models/activity_model.dart';

class PupilsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Recupera tutti i pupilli dell'utente loggato, con le relative attività associate per sommare le ore
  Future<List<Pupil>> getPupils() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('Utente non autenticato');
    final response = await _supabase
        .from('pupils')
        .select('*, activities(duration, activity_date)')
        .eq('user_id', currentUser.id)
        .order('name');
    final list = response as List<dynamic>;
    return list
        .map((json) => Pupil.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Recupera un singolo pupillo con le sue attività associate per i dettagli
  Future<Pupil> getPupilById(String id) async {
    final response = await _supabase
        .from('pupils')
        .select('*, activities(duration, activity_date)')
        .eq('id', id)
        .single();

    return Pupil.fromJson(response);
  }

  // Aggiunge un nuovo pupillo associato all'utente loggato
  Future<void> addPupil({
    required String name,
    required double maxHours,
    required double tarif,
    required double kmTarif,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('Utente non autenticato');
    await _supabase.from('pupils').insert({
      'name': name,
      'max_hours': maxHours,
      'tarif': tarif,
      'km_tarif': kmTarif,
      'user_id': currentUser.id,
    });
  }

  // Recupera le attività recenti di un determinato pupillo ordinate per data decrescente
  Future<List<Activity>> getRecentActivities(String pupilId) async {
    final response = await _supabase
        .from('activities')
        .select('*')
        .eq('pupil_id', pupilId)
        .order('activity_date', ascending: false)
        .order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list
        .map((json) => Activity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Aggiunge una nuova attività
  Future<void> addActivity({
    required String pupilId,
    required DateTime activityDate,
    required String type,
    double? duration,
    String? description,
    double? kilometers,
    double? stamp,
    double? otherExpenses,
  }) async {
    await _supabase.from('activities').insert({
      'pupil_id': pupilId,
      'activity_date': activityDate.toIso8601String().substring(
        0,
        10,
      ), // Formato YYYY-MM-DD
      'type': type,
      'duration': duration,
      'description': description?.isEmpty ?? true ? null : description,
      'kilometers': kilometers,
      'stamp': stamp,
      'other_expenses': otherExpenses,
    });
  }

  // Recupera tutte le attività dell'anno corrente per tutti i pupilli dell'utente
  Future<List<Activity>> getActivitiesForCurrentYear() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('Utente non autenticato');
    // Recupera prima i pupilli dell'utente loggato
    final pupilsResponse = await _supabase
        .from('pupils')
        .select('id')
        .eq('user_id', currentUser.id);
    final pupilIds = (pupilsResponse as List<dynamic>)
        .map((p) => p['id'] as String)
        .toList();
    if (pupilIds.isEmpty) return [];
    final currentYear = DateTime.now().year;
    final firstDayOfYear = '$currentYear-01-01';
    final lastDayOfYear = '$currentYear-12-31';
    final response = await _supabase
        .from('activities')
        .select('*')
        .inFilter('pupil_id', pupilIds)
        .gte('activity_date', firstDayOfYear)
        .lte('activity_date', lastDayOfYear)
        .order('activity_date', ascending: false);
    final list = response as List<dynamic>;
    return list
        .map((json) => Activity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Elimina un pupillo dal database
  Future<void> deletePupil(String pupilId) async {
    await _supabase.from('pupils').delete().eq('id', pupilId);
  }

  // Aggiorna un pupillo esistente nel database
  Future<void> updatePupil({
    required String id,
    required String name,
    required double maxHours,
    required double tarif,
    required double kmTarif,
  }) async {
    await _supabase
        .from('pupils')
        .update({
          'name': name,
          'max_hours': maxHours,
          'tarif': tarif,
          'km_tarif': kmTarif,
        })
        .eq('id', id);
  }

  // Elimina un'attività dal database
  Future<void> deleteActivity(String id) async {
    await _supabase.from('activities').delete().eq('id', id);
  }

  // Aggiorna un'attività esistente nel database
  Future<void> updateActivity({
    required String id,
    required DateTime activityDate,
    required String type,
    double? duration,
    String? description,
    double? kilometers,
    double? stamp,
    double? otherExpenses,
  }) async {
    await _supabase
        .from('activities')
        .update({
          'activity_date': activityDate.toIso8601String().substring(0, 10),
          'type': type,
          'duration': duration,
          'description': description?.isEmpty ?? true ? null : description,
          'kilometers': kilometers,
          'stamp': stamp,
          'other_expenses': otherExpenses,
        })
        .eq('id', id);
  }

  // Recupera una singola attività per ID
  Future<Activity> getActivityById(String id) async {
    final response = await _supabase
        .from('activities')
        .select('*')
        .eq('id', id)
        .single();
    return Activity.fromJson(response);
  }
}

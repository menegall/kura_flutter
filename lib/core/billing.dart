import '../features/home/models/activity_model.dart';

/// Riepilogo economico di un insieme di attività.
class BillingSummary {
  final double workedHours;
  final double totalKm;
  final double totalStamps;
  final double totalOtherExpenses;
  final double hoursCost;
  final double kmCost;
  final double grandTotal;

  const BillingSummary({
    required this.workedHours,
    required this.totalKm,
    required this.totalStamps,
    required this.totalOtherExpenses,
    required this.hoursCost,
    required this.kmCost,
    required this.grandTotal,
  });

  static const empty = BillingSummary(
    workedHours: 0,
    totalKm: 0,
    totalStamps: 0,
    totalOtherExpenses: 0,
    hoursCost: 0,
    kmCost: 0,
    grandTotal: 0,
  );
}

/// Calcola ore, km, spese e totale da fatturare per un elenco di attività.
///
/// Le regole devono restare allineate 1:1 con la edge function
/// `supabase/functions/generate-stat-pdf/index.ts` (sezione "Financial
/// calculations"): i km e i francobolli si sommano da *tutte* le attività,
/// non solo da quelle di tipo trasferta / mail.
BillingSummary computeBilling(
  List<Activity> activities, {
  required double tarif,
  required double kmTarif,
}) {
  double workedHours = 0;
  double totalKm = 0;
  double totalStamps = 0;
  double totalOtherExpenses = 0;

  for (final act in activities) {
    workedHours += act.duration ?? 0;
    totalKm += act.kilometers ?? 0;
    totalStamps += act.stamp ?? 0;
    totalOtherExpenses += act.otherExpenses ?? 0;
  }

  final hoursCost = workedHours * tarif;
  final kmCost = totalKm * kmTarif;
  final grandTotal = hoursCost + kmCost + totalStamps + totalOtherExpenses;

  return BillingSummary(
    workedHours: workedHours,
    totalKm: totalKm,
    totalStamps: totalStamps,
    totalOtherExpenses: totalOtherExpenses,
    hoursCost: hoursCost,
    kmCost: kmCost,
    grandTotal: grandTotal,
  );
}

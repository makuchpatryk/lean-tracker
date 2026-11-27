/// A calendar day on the device, without a time or a zone (BR-004: the day is the local device date).
final class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  /// The local calendar day of [local]. Only its local fields are read, never its UTC instant (BR-004).
  LocalDate.of(DateTime local) : this(local.year, local.month, local.day);

  /// Reads `yyyy-MM-dd`. Returns null for anything else, including a day that does not exist.
  static LocalDate? parseIso(String text) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) return null;
    final year = int.parse(match.group(1) ?? '');
    final month = int.parse(match.group(2) ?? '');
    final day = int.parse(match.group(3) ?? '');
    final date = LocalDate(year, month, day);
    // DateTime.utc rolls 2026-02-30 over to March; a valid day survives the round trip.
    return date.addDays(0) == date ? date : null;
  }

  final int year;
  final int month;
  final int day;

  /// The day [days] later (negative: earlier). Computed in UTC so a DST change cannot shift the date.
  LocalDate addDays(int days) {
    final moved = DateTime.utc(year, month, day + days);
    return LocalDate(moved.year, moved.month, moved.day);
  }

  /// The day as a local [DateTime] at midnight, for pickers.
  DateTime toDateTime() => DateTime(year, month, day);

  /// `yyyy-MM-dd`, the form stored and sent (PRD §13 `entry_date`).
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

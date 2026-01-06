/// Model representing a leave request for a specific day.
///
/// This class holds the date and selected time periods for a leave request.
class LeaveModel {
  LeaveModel(this.dateTime, int count)
      : selected = List<bool>.filled(count, false);

  /// The date of the leave.
  final DateTime dateTime;

  /// List of selected time codes (true = selected).
  final List<bool> selected;

  /// Checks if this model represents the same day as [other].
  bool isSameDay(DateTime other) {
    return dateTime.year == other.year &&
        dateTime.month == other.month &&
        dateTime.day == other.day;
  }

  /// Returns a formatted date string.
  String get formattedDate =>
      '${dateTime.year}/${dateTime.month}/${dateTime.day}';

  /// Returns true if any time slot is selected.
  bool get hasSelection => selected.any((bool s) => s);

  /// Returns the list of selected indices.
  List<int> get selectedIndices {
    final List<int> indices = <int>[];
    for (int i = 0; i < selected.length; i++) {
      if (selected[i]) {
        indices.add(i);
      }
    }
    return indices;
  }
}

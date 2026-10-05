import 'package:intl/intl.dart';

/// Date helpers that produce the relative labels used across the UI
/// ("Today, 09:15", "Yesterday, 18:40", "Oct 21, 2023").
abstract final class DateFormatter {
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _monthDay = DateFormat('MMM d');
  static final DateFormat _full = DateFormat('MMM d, yyyy');
  static final DateFormat _fullWithTime = DateFormat('MMM d, yyyy, HH:mm');

  static String relative(
    DateTime date, {
    required String today,
    required String yesterday,
    DateTime? now,
  }) {
    final DateTime current = now ?? DateTime.now();
    final DateTime d = DateTime(date.year, date.month, date.day);
    final DateTime t = DateTime(current.year, current.month, current.day);
    final int diff = t.difference(d).inDays;
    if (diff == 0) return '$today, ${_time.format(date)}';
    if (diff == 1) return '$yesterday, ${_time.format(date)}';
    if (date.year == current.year) return _monthDay.format(date);
    return _full.format(date);
  }

  static String short(DateTime date, {DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    if (date.year == current.year) return _monthDay.format(date);
    return _full.format(date);
  }

  static String full(DateTime date) => _fullWithTime.format(date);

  /// "3d ago", "5h ago", "just now".
  static String ago(DateTime date, {DateTime? now}) {
    final Duration diff = (now ?? DateTime.now()).difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}

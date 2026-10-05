/// Formats byte counts with tabular-friendly suffixes.
abstract final class FileSizeFormatter {
  static String format(int bytes) {
    if (bytes < 0) {
      return '—';
    }
    const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    int unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    if (unit == 0) {
      return '$bytes B';
    }
    final String digits = value >= 10 ? value.toStringAsFixed(1) : value.toStringAsFixed(2);
    return '$digits ${units[unit]}';
  }
}

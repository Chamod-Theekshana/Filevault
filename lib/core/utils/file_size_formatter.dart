import 'dart:math' as math;

/// Human readable byte formatting that matches the design mock-ups
/// ("4.2 MB", "64 GB", "840 KB").
abstract final class FileSizeFormatter {
  static const List<String> _units = <String>['B', 'KB', 'MB', 'GB', 'TB'];

  static String format(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    final int exponent =
        math.min((math.log(bytes) / math.log(1024)).floor(), _units.length - 1);
    final double value = bytes / math.pow(1024, exponent);
    if (exponent == 0) return '$bytes B';
    final String text = value >= 100 || value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(decimals);
    return '$text ${_units[exponent]}';
  }

  /// Formats a transfer speed such as "18 MB/s".
  static String speed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    return '${format(bytesPerSecond.round(), decimals: 0)}/s';
  }

  /// Formats a duration as "12s", "2m 05s" or "1h 12m".
  static String duration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) {
      final int s = d.inSeconds % 60;
      return '${d.inMinutes}m ${s.toString().padLeft(2, '0')}s';
    }
    final int m = d.inMinutes % 60;
    return '${d.inHours}h ${m.toString().padLeft(2, '0')}m';
  }

  /// Thousands separated count: 4280 -> "4,280".
  static String count(int value) {
    final String raw = value.toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final int remaining = raw.length - i;
      out.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) out.write(',');
    }
    return out.toString();
  }
}

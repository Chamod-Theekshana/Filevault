enum OperationType {
  copy,
  move,
  trash,
  delete,
  restore,
  compress,
  extract,
  encrypt,
  decrypt,
}

enum OperationStatus { queued, running, paused, completed, failed, cancelled }

extension OperationStatusX on OperationStatus {
  bool get isActive =>
      this == OperationStatus.queued ||
      this == OperationStatus.running ||
      this == OperationStatus.paused;

  bool get isFinished => !isActive;
}

/// A unit of work in the operation queue. Immutable – the controller emits a
/// new copy for every progress tick.
class FileOperation {
  const FileOperation({
    required this.id,
    required this.type,
    required this.sources,
    required this.createdAt,
    this.destination,
    this.status = OperationStatus.queued,
    this.processedBytes = 0,
    this.totalBytes = 0,
    this.processedFiles = 0,
    this.totalFiles = 0,
    this.currentFile,
    this.bytesPerSecond = 0,
    this.errorMessage,
    this.finishedAt,
    this.label,
  });

  final String id;
  final OperationType type;
  final List<String> sources;
  final String? destination;
  final OperationStatus status;
  final int processedBytes;
  final int totalBytes;
  final int processedFiles;
  final int totalFiles;
  final String? currentFile;
  final double bytesPerSecond;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? finishedAt;

  /// Optional display label (e.g. archive name).
  final String? label;

  double get progress {
    if (status == OperationStatus.completed) return 1;
    if (totalBytes > 0) return (processedBytes / totalBytes).clamp(0.0, 1.0);
    if (totalFiles > 0) return (processedFiles / totalFiles).clamp(0.0, 1.0);
    return 0;
  }

  int get percent => (progress * 100).round();

  Duration? get estimatedRemaining {
    if (bytesPerSecond <= 0 || totalBytes <= processedBytes) return null;
    final double seconds = (totalBytes - processedBytes) / bytesPerSecond;
    return Duration(seconds: seconds.ceil());
  }

  FileOperation copyWith({
    OperationStatus? status,
    int? processedBytes,
    int? totalBytes,
    int? processedFiles,
    int? totalFiles,
    String? currentFile,
    double? bytesPerSecond,
    String? errorMessage,
    DateTime? finishedAt,
    String? label,
    String? destination,
  }) {
    return FileOperation(
      id: id,
      type: type,
      sources: sources,
      destination: destination ?? this.destination,
      createdAt: createdAt,
      status: status ?? this.status,
      processedBytes: processedBytes ?? this.processedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      processedFiles: processedFiles ?? this.processedFiles,
      totalFiles: totalFiles ?? this.totalFiles,
      currentFile: currentFile ?? this.currentFile,
      bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
      errorMessage: errorMessage ?? this.errorMessage,
      finishedAt: finishedAt ?? this.finishedAt,
      label: label ?? this.label,
    );
  }
}

/// What to do when a destination file already exists.
enum ConflictResolution { replace, skip, keepBoth }

class ConflictDecision {
  const ConflictDecision(this.resolution, {this.applyToAll = false});

  final ConflictResolution resolution;
  final bool applyToAll;
}

/// Details handed to the UI when a conflict needs a decision.
class ConflictInfo {
  const ConflictInfo({
    required this.sourcePath,
    required this.destinationPath,
    required this.sourceSize,
    required this.destinationSize,
    required this.sourceModified,
    required this.destinationModified,
    required this.remaining,
  });

  final String sourcePath;
  final String destinationPath;
  final int sourceSize;
  final int destinationSize;
  final DateTime sourceModified;
  final DateTime destinationModified;

  /// How many more items are still to be processed after this one.
  final int remaining;
}

/// Persisted row for the operations history list.
class OperationRecord {
  const OperationRecord({
    required this.id,
    required this.type,
    required this.source,
    required this.destination,
    required this.status,
    required this.createdAt,
    this.finishedAt,
    this.errorMessage,
    this.fileCount = 0,
    this.totalBytes = 0,
  });

  final int id;
  final OperationType type;
  final String source;
  final String? destination;
  final OperationStatus status;
  final DateTime createdAt;
  final DateTime? finishedAt;
  final String? errorMessage;
  final int fileCount;
  final int totalBytes;

  static OperationRecord fromRow(Map<String, Object?> row) => OperationRecord(
        id: (row['id'] as num).toInt(),
        type: OperationType.values.firstWhere(
          (OperationType t) => t.name == row['type'],
          orElse: () => OperationType.copy,
        ),
        source: (row['source'] as String?) ?? '',
        destination: row['destination'] as String?,
        status: OperationStatus.values.firstWhere(
          (OperationStatus s) => s.name == row['status'],
          orElse: () => OperationStatus.completed,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (row['created_at'] as num).toInt()),
        finishedAt: row['finished_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (row['finished_at'] as num).toInt()),
        errorMessage: row['error_message'] as String?,
        fileCount: (row['file_count'] as num?)?.toInt() ?? 0,
        totalBytes: (row['total_bytes'] as num?)?.toInt() ?? 0,
      );
}

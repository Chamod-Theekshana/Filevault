import 'package:filevault/domain/models/file_operation.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:flutter_test/flutter_test.dart';

FileOperation op(String id, OperationStatus status) => FileOperation(
      id: id,
      type: OperationType.copy,
      sources: const <String>['/a'],
      createdAt: DateTime(2024),
      status: status,
    );

void main() {
  group('OperationsState', () {
    test('active returns the running or paused operation', () {
      const OperationsState empty = OperationsState();
      expect(empty.active, isNull);

      final OperationsState state = OperationsState(operations: <FileOperation>[
        op('1', OperationStatus.completed),
        op('2', OperationStatus.running),
        op('3', OperationStatus.queued),
      ]);
      expect(state.active?.id, '2');
      expect(state.queued.single.id, '3');
      expect(state.finished.single.id, '1');
      expect(state.hasActivity, isTrue);
    });

    test('hasActivity is false once everything settles', () {
      final OperationsState state = OperationsState(operations: <FileOperation>[
        op('1', OperationStatus.completed),
        op('2', OperationStatus.failed),
        op('3', OperationStatus.cancelled),
      ]);
      expect(state.hasActivity, isFalse);
      expect(state.active, isNull);
    });
  });

  group('FileOperation progress', () {
    test('uses bytes when known, falls back to file counts', () {
      final FileOperation bytes = op('1', OperationStatus.running)
          .copyWith(totalBytes: 1000, processedBytes: 250);
      expect(bytes.percent, 25);

      final FileOperation counted = op('2', OperationStatus.running)
          .copyWith(totalFiles: 4, processedFiles: 3);
      expect(counted.percent, 75);

      final FileOperation done = op('3', OperationStatus.completed);
      expect(done.progress, 1);
    });

    test('estimates the remaining time from the transfer speed', () {
      final FileOperation operation = op('1', OperationStatus.running).copyWith(
        totalBytes: 10 * 1024 * 1024,
        processedBytes: 2 * 1024 * 1024,
        bytesPerSecond: 1024 * 1024.0,
      );
      expect(operation.estimatedRemaining, const Duration(seconds: 8));
    });

    test('no estimate without a speed sample', () {
      expect(op('1', OperationStatus.running).estimatedRemaining, isNull);
    });
  });

  group('OperationStatus', () {
    test('classifies active and finished states', () {
      expect(OperationStatus.queued.isActive, isTrue);
      expect(OperationStatus.running.isActive, isTrue);
      expect(OperationStatus.paused.isActive, isTrue);
      expect(OperationStatus.completed.isFinished, isTrue);
      expect(OperationStatus.failed.isFinished, isTrue);
      expect(OperationStatus.cancelled.isFinished, isTrue);
    });
  });
}

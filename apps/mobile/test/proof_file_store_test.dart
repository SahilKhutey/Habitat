// Habitat Proof File Storage Engine Unit Tests
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/features/proof/data/proof_file_store.dart';

void main() {
  late ProofFileStore store;

  setUp(() {
    store = ProofFileStore.create();
  });

  group('ProofFileStore Unit Tests', () {
    test('computeSha256() computes valid 64-char hex SHA-256 digest', () {
      final sampleBytes = utf8.encode('HABITAT_SAMPLE_PROOF_DATA');
      final hash = store.computeSha256(sampleBytes);

      expect(hash.length, equals(64));
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash), isTrue);
    });

    test('saveProofBytes() saves file and tracks byte size accurately',
        () async {
      final sampleBytes = utf8.encode('PHOTO_BYTES_123456');
      final path = await store.saveProofBytes(
        taskId: 'task_001',
        attemptId: 'attempt_001',
        bytes: sampleBytes,
        extension: 'jpg',
      );

      expect(path, contains('task_001_attempt_001.jpg'));
      expect(await store.proofExists(path), isTrue);
      expect(await store.getFileByteSize(path), equals(sampleBytes.length));

      await store.deleteProof(path);
      expect(await store.proofExists(path), isFalse);
    });
  });
}

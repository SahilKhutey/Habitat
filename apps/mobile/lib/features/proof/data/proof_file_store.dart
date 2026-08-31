// Habitat Proof File Storage Engine
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

class ProofFileStore {
  final Map<String, List<int>> _memoryStorage = {};
  final String? _baseDirectory;

  ProofFileStore({String? baseDirectory}) : _baseDirectory = baseDirectory;

  factory ProofFileStore.create({String? baseDirectory}) {
    return ProofFileStore(baseDirectory: baseDirectory);
  }

  String computeSha256(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  Future<String> saveProofBytes({
    required String taskId,
    required String attemptId,
    required List<int> bytes,
    required String extension,
  }) async {
    final fileName = '${taskId}_$attemptId.$extension';
    final targetPath = _baseDirectory != null
        ? p.join(_baseDirectory!, fileName)
        : '/mock_proofs/$fileName';

    if (_baseDirectory != null) {
      final file = File(targetPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    } else {
      _memoryStorage[targetPath] = bytes;
    }

    return targetPath;
  }

  Future<bool> proofExists(String path) async {
    if (_baseDirectory != null) {
      return File(path).exists();
    }
    return _memoryStorage.containsKey(path);
  }

  Future<int> getFileByteSize(String path) async {
    if (_baseDirectory != null) {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    }
    return _memoryStorage[path]?.length ?? 0;
  }

  Future<void> deleteProof(String path) async {
    if (_baseDirectory != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } else {
      _memoryStorage.remove(path);
    }
  }
}

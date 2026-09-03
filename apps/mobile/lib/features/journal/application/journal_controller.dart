// Habitat Daily Journal Application Controller
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../database/local_database.dart';

class JournalController extends ChangeNotifier {
  final LocalDatabase _database;
  bool isLoading = false;
  String? errorMessage;

  JournalController({LocalDatabase? database})
      : _database = database ?? LocalDatabase.instance {
    _database.changes.addListener(_onDatabaseChanged);
  }

  List<LocalJournalEntry> get allEntries => _database.getAllJournalEntries();

  bool get hasEntryForToday => getEntryForDay(DateTime.now()) != null;

  LocalJournalEntry? getEntryForDay(DateTime day) {
    return _database.getJournalEntryForDay(day);
  }

  void saveEntry({
    required DateTime date,
    required String sentence,
    String emoji = '⚡',
    int rating = 5,
  }) {
    final existing = getEntryForDay(date);
    final now = DateTime.now();

    final entry = LocalJournalEntry(
      id: existing?.id ?? const Uuid().v4(),
      date: date,
      sentence: sentence,
      emoji: emoji,
      rating: rating,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    _database.saveJournalEntry(entry);
    notifyListeners();
  }

  void deleteEntry(String id) {
    _database.deleteJournalEntry(id);
    notifyListeners();
  }

  void _onDatabaseChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_onDatabaseChanged);
    super.dispose();
  }
}

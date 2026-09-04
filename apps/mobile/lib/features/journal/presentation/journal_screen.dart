// Habitat Real Daily Journal Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../application/journal_controller.dart';

class JournalScreen extends StatefulWidget {
  final JournalController? controller;

  const JournalScreen({super.key, this.controller});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late final JournalController _controller;
  bool _internalController = false;

  final _sentenceController = TextEditingController();
  String _selectedEmoji = '⚡';
  int _selectedRating = 5;
  DateTime _selectedDate = DateTime.now();

  final List<String> _emojis = ['⚡', '🔥', '🛡️', '🎯', '🌱', '🏆'];

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = JournalController();
      _internalController = true;
    }

    _loadTodayEntry();
  }

  void _loadTodayEntry() {
    final entry = _controller.getEntryForDay(_selectedDate);
    if (entry != null) {
      _sentenceController.text = entry.sentence;
      _selectedEmoji = entry.emoji;
      _selectedRating = entry.rating;
    } else {
      _sentenceController.clear();
      _selectedEmoji = '⚡';
      _selectedRating = 5;
    }
  }

  void _saveEntry() {
    final text = _sentenceController.text.trim();
    if (text.isEmpty) return;

    _controller.saveEntry(
      date: _selectedDate,
      sentence: text,
      emoji: _selectedEmoji,
      rating: _selectedRating,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: HabitatTheme.emeraldVictory,
        content: Text('Daily reflection persisted to local encrypted ledger.'),
      ),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final entries = _controller.allEntries;

        return Scaffold(
          backgroundColor: HabitatTheme.background,
          appBar: AppBar(
            title: const Text('DAILY DISCIPLINE JOURNAL'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Reflection Editor Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: HabitatTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HabitatTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TODAY'S ONE SENTENCE",
                        style: TextStyle(
                          color: HabitatTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _sentenceController,
                        maxLines: 3,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                              'What defined your discipline and focus today?',
                          hintStyle:
                              const TextStyle(color: HabitatTheme.textMuted),
                          filled: true,
                          fillColor: const Color(0xFF141419),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Emoji Selector & Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: _emojis.map((emoji) {
                              final isSelected = _selectedEmoji == emoji;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedEmoji = emoji),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? HabitatTheme.amberFocus
                                            .withOpacity(0.3)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? HabitatTheme.amberFocus
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(emoji,
                                      style: const TextStyle(fontSize: 18)),
                                ),
                              );
                            }).toList(),
                          ),
                          DropdownButton<int>(
                            value: _selectedRating,
                            dropdownColor: const Color(0xFF1E1E26),
                            underline: const SizedBox(),
                            items: [1, 2, 3, 4, 5].map((r) {
                              return DropdownMenuItem(
                                value: r,
                                child: Text(
                                  '★ $r / 5',
                                  style: const TextStyle(
                                      color: HabitatTheme.amberFocus,
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _selectedRating = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveEntry,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('COMMIT REFLECTION'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HabitatTheme.amberFocus,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 2. Past Journal Entries
                const Text(
                  'PAST REFLECTIONS',
                  style: TextStyle(
                    color: HabitatTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                if (entries.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: HabitatTheme.surfacePrimary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HabitatTheme.borderSubtle),
                    ),
                    child: const Center(
                      child: Text(
                        'No reflections recorded yet.\nWrite today\'s one sentence above to begin your discipline log.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: HabitatTheme.textMuted,
                            fontSize: 13,
                            height: 1.5),
                      ),
                    ),
                  )
                else
                  ...entries.map((e) {
                    final dateStr =
                        '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: HabitatTheme.surfacePrimary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: HabitatTheme.borderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                          color: HabitatTheme.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '★ ${e.rating}/5',
                                      style: const TextStyle(
                                          color: HabitatTheme.amberFocus,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  e.sentence,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

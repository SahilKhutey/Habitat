// Create Custom Task Wizard Screen
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

class CreateCustomTaskScreen extends StatefulWidget {
  const CreateCustomTaskScreen({super.key});

  @override
  State<CreateCustomTaskScreen> createState() => _CreateCustomTaskScreenState();
}

class _CreateCustomTaskScreenState extends State<CreateCustomTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<TextEditingController> _instructionControllers = [
    TextEditingController(text: 'Perform physical action'),
    TextEditingController(text: 'Capture proof clearly in bright light'),
  ];

  String _category = 'physical';
  String _difficulty = 'MEDIUM';
  String _proofType = 'PHOTO';

  int get _calculatedXp =>
      _difficulty == 'HARD' ? 80 : (_difficulty == 'MEDIUM' ? 60 : 40);

  void _addInstructionStep() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  void _removeInstructionStep(int index) {
    if (_instructionControllers.length > 1) {
      setState(() {
        _instructionControllers.removeAt(index);
      });
    }
  }

  void _handleSave() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a mission title.')),
      );
      return;
    }

    final instructions = _instructionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please add at least one execution instruction step.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Custom mission "${_titleController.text}" created successfully!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('NEW CUSTOM MISSION'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Mission Title',
                  hintText: 'e.g. 20 Jumping Jacks, Make Green Smoothie...',
                  filled: true,
                  fillColor: HabitatTheme.surfacePrimary,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description / Purpose',
                  hintText: 'Why is this habit important for your discipline?',
                  filled: true,
                  fillColor: HabitatTheme.surfacePrimary,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),

              // Category & Proof Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      dropdownColor: HabitatTheme.surfacePrimary,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: HabitatTheme.surfacePrimary,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'morning', child: Text('🌅 Morning')),
                        DropdownMenuItem(
                            value: 'physical', child: Text('💪 Physical')),
                        DropdownMenuItem(
                            value: 'personal', child: Text('🧼 Personal')),
                        DropdownMenuItem(value: 'mind', child: Text('🧠 Mind')),
                        DropdownMenuItem(
                            value: 'environment',
                            child: Text('🧹 Environment')),
                      ],
                      onChanged: (val) =>
                          setState(() => _category = val ?? 'physical'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _proofType,
                      dropdownColor: HabitatTheme.surfacePrimary,
                      decoration: InputDecoration(
                        labelText: 'Proof Method',
                        filled: true,
                        fillColor: HabitatTheme.surfacePrimary,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'PHOTO', child: Text('📸 Photo')),
                        DropdownMenuItem(
                            value: 'VIDEO', child: Text('🎥 Video')),
                      ],
                      onChanged: (val) =>
                          setState(() => _proofType = val ?? 'PHOTO'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Difficulty Selector
              const Text('DIFFICULTY & BASE XP REWARD',
                  style: TextStyle(
                      color: HabitatTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildDiffChoice('EASY', 'Easy (40 XP)'),
                  const SizedBox(width: 8),
                  _buildDiffChoice('MEDIUM', 'Medium (60 XP)'),
                  const SizedBox(width: 8),
                  _buildDiffChoice('HARD', 'Hard (80 XP)'),
                ],
              ),
              const SizedBox(height: 28),

              // Step-by-step Instructions builder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('EXECUTION INSTRUCTIONS',
                      style: TextStyle(
                          color: HabitatTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  TextButton.icon(
                    onPressed: _addInstructionStep,
                    icon: const Icon(Icons.add,
                        size: 16, color: HabitatTheme.amberFocus),
                    label: const Text('Add Step',
                        style: TextStyle(
                            color: HabitatTheme.amberFocus, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ..._instructionControllers.asMap().entries.map((entry) {
                final idx = entry.key;
                final ctrl = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: HabitatTheme.surfaceSecondary,
                        child: Text('${idx + 1}',
                            style: const TextStyle(
                                color: HabitatTheme.amberFocus,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          decoration: InputDecoration(
                            hintText: 'Step ${idx + 1} action...',
                            filled: true,
                            fillColor: HabitatTheme.surfacePrimary,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      if (_instructionControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: HabitatTheme.textMuted, size: 18),
                          onPressed: () => _removeInstructionStep(idx),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HabitatTheme.amberFocus,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _handleSave,
                  child: Text(
                    'CREATE MISSION (+$_calculatedXp XP)',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiffChoice(String value, String label) {
    final isSelected = _difficulty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? HabitatTheme.amberFocus.withOpacity(0.15)
                : HabitatTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected
                    ? HabitatTheme.amberFocus
                    : HabitatTheme.surfaceBorder),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: isSelected
                    ? HabitatTheme.amberFocus
                    : HabitatTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

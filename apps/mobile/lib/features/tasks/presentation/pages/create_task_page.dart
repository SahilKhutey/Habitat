// Habitat 7-Step Guided Task Creation Wizard Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/create_task_controller.dart';
import '../../domain/models/alarm_model.dart';
import '../../domain/models/task_model.dart';
import '../../domain/services/task_service.dart';
import '../widgets/retry_configuration.dart';
import '../widgets/schedule_picker.dart';
import '../widgets/verification_selector.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  late final CreateTaskController _controller;
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _instructionController;

  @override
  void initState() {
    super.initState();
    _controller =
        CreateTaskController(taskService: TaskService(LocalDatabase.instance));
    _titleController = TextEditingController(text: _controller.title);
    _descController = TextEditingController(text: _controller.description);
    _instructionController =
        TextEditingController(text: _controller.actionInstruction);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _instructionController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_controller.currentStep == 0) {
      _controller.updateBasicInfo(
        newTitle: _titleController.text,
        newDescription: _descController.text,
      );
    } else if (_controller.currentStep == 2) {
      _controller.updateActionAndVerification(
        newInstruction: _instructionController.text,
      );
    }

    if (_controller.currentStep < 6) {
      _controller.nextStep();
    } else {
      _controller.saveTask();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ New Daily Discipline Created & Scheduled!'),
          backgroundColor: HabitatTheme.surfacePrimary,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final step = _controller.currentStep;
        final progress = (step + 1) / 7.0;

        return Scaffold(
          backgroundColor: HabitatTheme.background,
          appBar: AppBar(
            title: Text('CREATE DISCIPLINE (${step + 1}/7)'),
            backgroundColor: HabitatTheme.background,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: HabitatTheme.surfaceSecondary,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          HabitatTheme.growthGreen),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildStepContent(step),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Buttons Row
                  Row(
                    children: [
                      if (step > 0) ...[
                        Expanded(
                          flex: 3,
                          child: OutlinedButton(
                            onPressed: _controller.previousStep,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                  color: HabitatTheme.surfaceBorder),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 7,
                        child: ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HabitatTheme.growthGreen,
                            foregroundColor: HabitatTheme.forest,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            step == 6 ? 'CONFIRM & SCHEDULE TASK' : 'CONTINUE',
                            style: const TextStyle(
                              fontFamily: HabitatTheme.fontHeading,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildStep0BasicInfo();
      case 1:
        return _buildStep1Schedule();
      case 2:
        return _buildStep2Action();
      case 3:
        return _buildStep3Verification();
      case 4:
        return _buildStep4Alarm();
      case 5:
        return _buildStep5Retry();
      case 6:
      default:
        return _buildStep6Review();
    }
  }

  // Step 0: Basic Information
  Widget _buildStep0BasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STEP 1: BASIC INFORMATION',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HabitatTheme.youngLeaf,
                letterSpacing: 1.2)),
        const SizedBox(height: 4),
        const Text('What discipline will you practice?',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 20),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Task Title',
            labelStyle: const TextStyle(color: HabitatTheme.textSecondary),
            filled: true,
            fillColor: HabitatTheme.surfacePrimary,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: HabitatTheme.surfaceBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: HabitatTheme.surfaceBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: HabitatTheme.growthGreen)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _descController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Description / Purpose',
            labelStyle: const TextStyle(color: HabitatTheme.textSecondary),
            filled: true,
            fillColor: HabitatTheme.surfacePrimary,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: HabitatTheme.surfaceBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: HabitatTheme.surfaceBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: HabitatTheme.growthGreen)),
          ),
        ),
        const SizedBox(height: 20),
        const Text('CATEGORY',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HabitatTheme.youngLeaf,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TaskCategory.values.map((cat) {
            final isSelected = _controller.category == cat;
            return ChoiceChip(
              label: Text(cat.name.toUpperCase()),
              selected: isSelected,
              selectedColor: HabitatTheme.growthGreen,
              backgroundColor: HabitatTheme.surfacePrimary,
              labelStyle: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? HabitatTheme.forest : Colors.white,
              ),
              onSelected: (_) => _controller.updateBasicInfo(newCategory: cat),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Step 1: Schedule
  Widget _buildStep1Schedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STEP 2: SCHEDULE & TIMING',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HabitatTheme.youngLeaf,
                letterSpacing: 1.2)),
        const SizedBox(height: 4),
        const Text('When should this happen?',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 20),
        SchedulePicker(
          selectedRecurrence: _controller.recurrence,
          timeOfDay: _controller.timeOfDay,
          repeatDays: _controller.repeatDays,
          onRecurrenceChanged: (rec) =>
              _controller.updateSchedule(newRecurrence: rec),
          onTimeChanged: (t) => _controller.updateSchedule(newTime: t),
          onDaysChanged: (days) => _controller.updateSchedule(newDays: days),
        ),
      ],
    );
  }

  // Step 2: Action Definition
  Widget _buildStep2Action() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STEP 3: ACTION SPECIFICATION',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HabitatTheme.youngLeaf,
                letterSpacing: 1.2)),
        const SizedBox(height: 4),
        const Text('What must you perform?',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 20),
        TextField(
          controller: _instructionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Action Instructions for User',
            labelStyle: const TextStyle(color: HabitatTheme.textSecondary),
            filled: true,
            fillColor: HabitatTheme.surfacePrimary,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: HabitatTheme.surfaceBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: HabitatTheme.surfaceBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: HabitatTheme.growthGreen)),
          ),
        ),
      ],
    );
  }

  // Step 3: Verification
  Widget _buildStep3Verification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STEP 4: PROOF VERIFICATION',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HabitatTheme.youngLeaf,
                letterSpacing: 1.2)),
        const SizedBox(height: 4),
        const Text('How will completion be verified?',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 20),
        VerificationSelector(
          selectedActionType: _controller.actionType,
          selectedVerificationType: _controller.verificationType,
          onActionTypeChanged: (type) =>
              _controller.updateActionAndVerification(newActionType: type),
          onVerificationTypeChanged: (vType) => _controller
              .updateActionAndVerification(newVerificationType: vType),
        ),
      ],
    );
  }

  // Step 4: Alarm
  Widget _buildStep4Alarm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STEP 5: ALARM & REMINDER',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HabitatTheme.youngLeaf,
                letterSpacing: 1.2)),
        const SizedBox(height: 4),
        const Text('Wake-up siren configuration',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HabitatTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HabitatTheme.surfaceBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ARM NATIVE WAKE-UP ALARM',
                      style: TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Rings device at exact scheduled time',
                      style: TextStyle(
                          fontFamily: HabitatTheme.fontBody,
                          fontSize: 11,
                          color: HabitatTheme.textSecondary)),
                ],
              ),
              Switch(
                value: _controller.alarmEnabled,
                activeColor: HabitatTheme.growthGreen,
                onChanged: (val) => _controller.updateAlarm(enabled: val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('DISCIPLINE MODE',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HabitatTheme.youngLeaf,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Row(
          children: DisciplineMode.values.map((mode) {
            final isSelected = _controller.disciplineMode == mode;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(mode.name.toUpperCase()),
                  selected: isSelected,
                  selectedColor: HabitatTheme.growthGreen,
                  backgroundColor: HabitatTheme.surfacePrimary,
                  labelStyle: TextStyle(
                    fontFamily: HabitatTheme.fontHeading,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? HabitatTheme.forest : Colors.white,
                  ),
                  onSelected: (_) => _controller.updateAlarm(mode: mode),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Step 5: Retry Rules
  Widget _buildStep5Retry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STEP 6: ESCALATION RETRY RULES',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HabitatTheme.youngLeaf,
                letterSpacing: 1.2)),
        const SizedBox(height: 4),
        const Text('Anti-snooze retry protocol',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 20),
        RetryConfiguration(
          retryEnabled: _controller.retryEnabled,
          retryIntervalMinutes: _controller.retryIntervalMinutes,
          maxAttempts: _controller.maxAttempts,
          onEnabledChanged: (val) => _controller.updateRetryRules(enabled: val),
          onIntervalChanged: (val) =>
              _controller.updateRetryRules(intervalMinutes: val),
          onMaxAttemptsChanged: (val) =>
              _controller.updateRetryRules(maxRetries: val),
        ),
      ],
    );
  }

  // Step 6: Review
  Widget _buildStep6Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STEP 7: REVIEW & CONFIRM',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HabitatTheme.youngLeaf,
                letterSpacing: 1.2)),
        const SizedBox(height: 4),
        const Text('Review Discipline Commitment',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HabitatTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: HabitatTheme.growthGreen.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleController.text.isEmpty
                    ? 'Daily Discipline'
                    : _titleController.text,
                style: const TextStyle(
                    fontFamily: HabitatTheme.fontHeading,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                  '${_controller.timeOfDay} • ${_controller.recurrence.name.toUpperCase()}',
                  style: const TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 13,
                      color: HabitatTheme.youngLeaf,
                      fontWeight: FontWeight.w700)),
              const Divider(height: 24, color: HabitatTheme.surfaceBorder),
              _buildReviewRow(
                  'Category', _controller.category.name.toUpperCase()),
              _buildReviewRow(
                  'Proof Method', _controller.actionType.name.toUpperCase()),
              _buildReviewRow(
                  'Alarm State',
                  _controller.alarmEnabled
                      ? 'Armed (Siren Enabled)'
                      : 'Disabled'),
              _buildReviewRow('Retry Escalation',
                  '${_controller.retryIntervalMinutes} Min (Max ${_controller.maxAttempts} Attempts)'),
              _buildReviewRow('Base Reward', '+${_controller.calculatedXp} XP'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: HabitatTheme.fontBody,
                  fontSize: 12,
                  color: HabitatTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

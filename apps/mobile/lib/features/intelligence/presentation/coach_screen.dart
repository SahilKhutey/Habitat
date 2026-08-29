// AI Discipline Coach Mobile Presentation HUD Screen
import 'package:flutter/material.dart';
import '../../../../packages/design_system/lib/design_system.dart';

class CoachScreen extends StatefulWidget {
  final String userId;

  const CoachScreen({
    super.key,
    this.userId = 'default-user',
  });

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content': 'Good morning. You completed 8 of 10 planned tasks yesterday. Your morning momentum remains high. What would you like help with today?',
      'action': null,
    }
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _textController.clear();
    });

    // Simulate structured response
    Future.delayed(const Duration(milliseconds: 400), () {
      setState(() {
        if (text.toLowerCase().contains('plan')) {
          _messages.add({
            'role': 'assistant',
            'content': 'Here is your structured plan for today. You have 3 primary commitments scheduled. Your first focus block starts at 07:00 AM.',
            'action': {
              'type': 'SHOW_PLAN',
              'title': "Today's Structured Schedule",
              'description': '3 commitments • 0 conflicts • 55 min total focus',
            }
          });
        } else if (text.toLowerCase().contains('why') || text.toLowerCase().contains('struggling')) {
          _messages.add({
            'role': 'assistant',
            'content': 'Observation: Tasks scheduled after 21:30 encounter friction due to accumulated cognitive fatigue. Moving key commitments 30 minutes earlier significantly increases execution reliability.',
            'action': {
              'type': 'PROPOSE_SCHEDULE_CHANGE',
              'title': 'Optimize Schedule Window',
              'description': 'Move Evening Reflection: 22:00 → 21:30',
            }
          });
        } else {
          _messages.add({
            'role': 'assistant',
            'content': 'I am monitoring your discipline patterns and active streaks. Stay focused on your primary commitments.',
            'action': null,
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'DISCIPLINE COACH',
          style: AppTypography.titleSmall.copyWith(letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick Action Prompt Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  _buildPromptChip('Plan Today', Icons.calendar_today),
                  const SizedBox(width: 8),
                  _buildPromptChip('Why Did I Miss Tasks?', Icons.help_outline),
                  const SizedBox(width: 8),
                  _buildPromptChip('Simplify Routine', Icons.tune),
                  const SizedBox(width: 8),
                  _buildPromptChip('Review Progress', Icons.insights),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // Message List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.indigoHero : const Color(0xFF15181E),
                        borderRadius: AppRadii.radiusMedium,
                        border: Border.all(color: isUser ? Colors.transparent : Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['content'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                          ),
                          if (msg['action'] != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E222B),
                                borderRadius: AppRadii.radiusSmall,
                                border: Border.all(color: AppColors.amberFocus.withOpacity(0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.bolt, color: AppColors.amberFocus, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        (msg['action']['title'] as String),
                                        style: const TextStyle(color: AppColors.amberFocus, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (msg['action']['description'] as String),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.emeraldVictory,
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusSmall),
                                          ),
                                          onPressed: () {},
                                          child: const Text('Accept Change', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.white24),
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusSmall),
                                          ),
                                          onPressed: () {},
                                          child: const Text('Keep Current', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Message Input Bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: Color(0xFF15181E),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Ask your coach...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.cyanDiscovery),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, color: AppColors.cyanDiscovery, size: 14),
      label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFF15181E),
      side: const BorderSide(color: Colors.white12),
      shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusSmall),
      onPressed: () => _sendMessage(label),
    );
  }
}

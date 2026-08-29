// Guided OEM Step Widget for Habitat Alarm Onboarding
import 'package:flutter/material.dart';

class ReliabilityStepItem extends StatelessWidget {
  final int stepNumber;
  final String text;

  const ReliabilityStepItem({
    Key? key,
    required this.stepNumber,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3B82F6), width: 1),
            ),
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF60A5FA),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFD1D5DB),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

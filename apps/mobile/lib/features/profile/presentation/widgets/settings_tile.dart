// Habitat Predictable Settings Row Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggleChanged;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.toggleValue,
    this.onToggleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDestructive ? Colors.redAccent : Colors.white;
    final iconColor =
        isDestructive ? Colors.redAccent : HabitatTheme.growthGreen;

    Widget? effectiveTrailing = trailing;
    if (toggleValue != null && onToggleChanged != null) {
      effectiveTrailing = Switch(
        value: toggleValue!,
        activeColor: HabitatTheme.growthGreen,
        onChanged: onToggleChanged,
      );
    } else if (effectiveTrailing == null && onTap != null) {
      effectiveTrailing = const Icon(Icons.chevron_right,
          color: HabitatTheme.textMuted, size: 20);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: toggleValue != null && onToggleChanged != null
            ? () => onToggleChanged!(!toggleValue!)
            : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: HabitatTheme.fontHeading,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontBody,
                          fontSize: 12,
                          color: HabitatTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (effectiveTrailing != null) effectiveTrailing,
            ],
          ),
        ),
      ),
    );
  }
}

// Habitat Grouped Settings Section Container
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: HabitatTheme.fontHeading,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: HabitatTheme.youngLeaf,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: HabitatTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HabitatTheme.surfaceBorder),
          ),
          child: Column(
            children: List.generate(children.length, (index) {
              final isLast = index == children.length - 1;
              return Column(
                children: [
                  children[index],
                  if (!isLast)
                    const Divider(
                        height: 1,
                        indent: 52,
                        color: HabitatTheme.surfaceBorder),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

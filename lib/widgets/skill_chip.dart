import 'package:flutter/material.dart';
import 'package:masar_jobs/models/skill.dart';

class SkillChip extends StatelessWidget {
  final Skill skill;

  const SkillChip({Key? key, required this.skill}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(skill.name ?? ''),
      backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
      side: BorderSide(color: Theme.of(context).colorScheme.secondary),
    );
  }
}

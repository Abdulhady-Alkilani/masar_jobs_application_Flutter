import 'package:flutter/material.dart';
import 'neumorphic_card.dart';

class NeumorphicButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isCircle;
  final EdgeInsets padding;

  const NeumorphicButton({
    Key? key,
    required this.child,
    this.onTap,
    this.isCircle = false,
    this.padding = const EdgeInsets.all(12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicCard(
        padding: padding,
        isCircle: isCircle,
        child: child,
      ),
    );
  }
}

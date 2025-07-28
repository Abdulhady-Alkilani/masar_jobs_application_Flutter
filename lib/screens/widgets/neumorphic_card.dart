import 'package:flutter/material.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool isCircle;

  const NeumorphicCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.isCircle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: isCircle ? null : BorderRadius.circular(20),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }
}


import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// A custom loading indicator using a Rive animation.
///
/// This widget displays a looping Rive animation from the specified asset file.
/// It is configured to use the "animated_icons_pack.riv" file and defaults
/// to the "TIMER" state machine animation, which is often suitable for loading.
class RiveLoadingIndicator extends StatelessWidget {
  final double size;

  const RiveLoadingIndicator({
    super.key,
    this.size = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const RiveAnimation.asset(
        'assets/rive/animated_icons_pack.riv',
        fit: BoxFit.contain,
        stateMachines: ['TIMER'], // A common animation name in icon packs
      ),
    );
  }
}

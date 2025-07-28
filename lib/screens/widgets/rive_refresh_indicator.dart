// lib/widgets/rive_refresh_indicator.dart

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

class RiveRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const RiveRefreshIndicator({
    Key? key,
    required this.child,
    required this.onRefresh,
  }) : super(key: key);

  @override
  _RiveRefreshIndicatorState createState() => _RiveRefreshIndicatorState();
}

class _RiveRefreshIndicatorState extends State<RiveRefreshIndicator> {
  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: widget.onRefresh,
      offsetToArmed: 100,
      builder: (BuildContext context, Widget child, IndicatorController controller) {
        return Stack(
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.only(top: 20),
                    child: Opacity(
                      opacity: controller.value.clamp(0.0, 1.0),
                      child: controller.isLoading
                          ? const CircularProgressIndicator()
                          : Icon(
                              Icons.arrow_downward,
                              color: Theme.of(context).primaryColor,
                              size: 30 * controller.value,
                            ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(0.0, controller.value * 100),
                  child: child,
                );
              },
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
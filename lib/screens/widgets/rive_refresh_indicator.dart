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
  // --- Rive State Machine and Inputs ---
  SMIInput<double>? _pullInput; // سيتحكم في مدى سحب اليد
  SMIInput<bool>? _isSearchingInput; // سيقوم بتشغيل/إيقاف حركة البحث
  Artboard? _riveArtboard;

  @override
  void initState() {
    super.initState();
    // تحميل ملف Rive
    rootBundle.load('assets/rive/search_hand.riv').then(
          (data) async {
        try {
          final file = RiveFile.import(data);
          final artboard = file.mainArtboard;
          // اسم الـ State Machine يجب أن يطابق الاسم في محرر Rive
          var controller = StateMachineController.fromArtboard(artboard, 'Searching');
          if (controller != null) {
            artboard.addController(controller);
            // أسماء الـ Inputs يجب أن تطابق الأسماء في محرر Rive
            _pullInput = controller.findInput<double>('pull');
            _isSearchingInput = controller.findInput<bool>('isSearching');
          }
          setState(() => _riveArtboard = artboard);
        } catch (e) {
          print("Error loading Rive file: $e");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: widget.onRefresh,
      // المسافة التي يجب سحبها لتشغيل onRefresh
      offsetToArmed: 150,
      builder: (BuildContext context, Widget child, IndicatorController controller) {
        // الاستماع لتغيرات حالة السحب
        controller.addListener(() {
          // قيمة السحب تتراوح من 0.0 إلى 1.0
          // نضربها في 100 لتناسب الـ input في Rive (الذي عادة ما يكون من 0 إلى 100)
          _pullInput?.value = controller.value * 100;

          // تشغيل وإيقاف حركة البحث بناءً على حالة الـ Indicator
          if (controller.isArmed || controller.isLoading) {
            _isSearchingInput?.value = true;
          } else {
            _isSearchingInput?.value = false;
          }
        });

        return Stack(
          children: [
            // عرض حركة Rive في الأعلى
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 150,
                    // تغيير شفافية الحركة أثناء السحب
                    child: Opacity(
                      opacity: controller.value.clamp(0.0, 1.0),
                      child: _riveArtboard == null
                          ? const SizedBox()
                          : Rive(artboard: _riveArtboard!),
                    ),
                  ),
                );
              },
            ),
            // عرض المحتوى الرئيسي (القائمة)
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                // تحريك القائمة للأسفل مع حركة السحب
                return Transform.translate(
                  offset: Offset(0.0, controller.value * 150),
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
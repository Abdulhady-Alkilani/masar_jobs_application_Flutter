// lib/widgets/empty_state_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRefresh;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. الأيقونة الكبيرة مع حركة
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: 80,
                color: theme.primaryColor,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
              delay: 300.ms,
              duration: 2000.ms,
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.1, 1.1),
              curve: Curves.easeInOut,
            )
                .then()
                .shimmer(duration: 1500.ms, color: theme.colorScheme.secondary.withOpacity(0.5)),

            const SizedBox(height: 32),

            // 2. العنوان
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),

            const SizedBox(height: 12),

            // 3. الرسالة التوضيحية
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),

            // 4. زر تحديث (اختياري)
            if (onRefresh != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('حاول مرة أخرى'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5),
            ]
          ],
        ),
      ),
    );
  }
}
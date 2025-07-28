import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

import 'package:masar_jobs/screens/wrapper_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WrapperScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Image.asset(
          'assets/image/logo.png',
          width: 250,
          height: 250,
        ).animate()
         .fadeIn(duration: 1200.ms, curve: Curves.easeOut)
         .scale(duration: 1200.ms, curve: Curves.easeOut, begin: const Offset(0.8, 0.8)),
      ),
    );
  }
}

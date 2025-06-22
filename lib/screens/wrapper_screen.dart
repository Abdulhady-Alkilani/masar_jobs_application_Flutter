// lib/screens/wrapper_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// استيراد شاشات الأدوار المختلفة
import 'consultant/consultant_home_screen.dart';
import 'home_screen.dart';
import 'admin/admin_panel_screen.dart';
import 'login_screen.dart';
import 'manager/manager_home_screen.dart'; // <-- 1. استيراد شاشة مدير الشركة


class WrapperScreen extends StatefulWidget {
  const WrapperScreen({super.key});

  @override
  _WrapperScreenState createState() => _WrapperScreenState();
}

class _WrapperScreenState extends State<WrapperScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      final userType = authProvider.user?.type;

      switch (userType) {
        case 'Admin':
          return const AdminPanelScreen();

        case 'خبير استشاري':
          return const ConsultantHomeScreen();

        case 'مدير شركة':
        // <-- 2. تم تفعيل التوجيه لشاشة مدير الشركة
          return const ManagerHomeScreen();

        case 'خريج':
        default:
          return const HomeScreen();
      }
    } else {
      return const LoginScreen();
    }
  }
}
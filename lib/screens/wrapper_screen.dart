import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // تأكد من المسار
import 'login_screen.dart'; // تأكد من المسار
import 'home_screen.dart'; // تأكد من المسار (سننشئها لاحقاً)

class WrapperScreen extends StatefulWidget {
  const WrapperScreen({Key? key}) : super(key: key);

  @override
  _WrapperScreenState createState() => _WrapperScreenState();
}

class _WrapperScreenState extends State<WrapperScreen> {
  @override
  void initState() {
    super.initState();
    // عند تهيئة الشاشة، تحقق من حالة المصادقة المخزنة
    Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    // استمع إلى حالة المصادقة من AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);

    // إذا كان يتم التحميل، اعرض مؤشر تحميل
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // إذا كان المستخدم مصادق عليه، اعرض الشاشة الرئيسية
    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      // إذا لم يكن مصادق عليه، اعرض شاشة تسجيل الدخول
      return const LoginScreen();
    }
  }
}
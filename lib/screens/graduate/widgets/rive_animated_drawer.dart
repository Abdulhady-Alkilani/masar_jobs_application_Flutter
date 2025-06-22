// lib/screens/graduate/widgets/rive_animated_drawer.dart

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

// استيراد الشاشات
import '../../user_profile_screen.dart';
import '../my_applications_screen.dart';
// ... استيراد باقي الشاشات

class RiveAnimatedDrawer extends StatefulWidget {
  const RiveAnimatedDrawer({super.key});
  @override
  State<RiveAnimatedDrawer> createState() => _RiveAnimatedDrawerState();
}

class _RiveAnimatedDrawerState extends State<RiveAnimatedDrawer> {
  SMIBool? homeTrigger, searchTrigger, timerTrigger, bellTrigger, userTrigger;
  int _selectedIndex = 0;

  void _onRiveIconInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(artboard, 'main');
    artboard.addController(controller!);
    homeTrigger = controller.findInput<bool>('isHome') as SMIBool;
    searchTrigger = controller.findInput<bool>('isSearch') as SMIBool;
    timerTrigger = controller.findInput<bool>('isTimer') as SMIBool;
    bellTrigger = controller.findInput<bool>('isBell') as SMIBool;
    userTrigger = controller.findInput<bool>('isUser') as SMIBool;

    // تفعيل الأيقونة الأولى تلقائياً
    homeTrigger?.value = true;
  }

  void _triggerAnimation(int index) {
    // إطفاء كل الحركات
    homeTrigger?.value = false;
    searchTrigger?.value = false;
    timerTrigger?.value = false;
    bellTrigger?.value = false;
    userTrigger?.value = false;

    // تشغيل الحركة المطلوبة
    switch (index) {
      case 0: homeTrigger?.value = true; break;
      case 1: searchTrigger?.value = true; break;
      case 2: timerTrigger?.value = true; break;
      case 3: bellTrigger?.value = true; break;
      case 4: userTrigger?.value = true; break;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        color: const Color(0xFF1D2A3A), // خلفية داكنة جداً
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس القائمة
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 24, child: Text('M')),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.firstName ?? 'المستخدم', style: const TextStyle(color: Colors.white, fontSize: 18)),
                        const Text("خريج", style: TextStyle(color: Colors.white54)),
                      ],
                    )
                  ],
                ),
              ),

              // عناصر القائمة المتحركة
              _buildRiveMenuItem(0, "isHome", "الصفحة الرئيسية", () => Navigator.pop(context)),
              _buildRiveMenuItem(1, "isSearch", "طلباتي للتوظيف", () => _navigateTo(context, const MyApplicationsScreen())),
              _buildRiveMenuItem(2, "isTimer", "دوراتي المسجلة", () {}),
              _buildRiveMenuItem(3, "isBell", "توصيات لك", () {}),
              _buildRiveMenuItem(4, "isUser", "ملفي الشخصي", () => _navigateTo(context, const UserProfileScreen())),

              const Spacer(),
              // زر تسجيل الخروج
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white70),
                title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white70)),
                onTap: () => context.read<AuthProvider>().logout(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiveMenuItem(int index, String stateMachineName, String title, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        _triggerAnimation(index);
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _selectedIndex == index ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
        ),
        child: Row(
          children: [
            SizedBox(
              height: 36,
              width: 36,
              child: RiveAnimation.asset(
                'assets/rive/animated_icons_pack.riv',
                stateMachines: const ['main'],
                onInit: _onRiveIconInit,
              ),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    });
  }
}
// lib/screens/manager/manager_home_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// --- استيراد الملفات اللازمة ---
import '../../models/company.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/managed_company_provider.dart';
import '../user_profile_screen.dart';
import 'create_company_request_screen.dart';
import 'edit_company_screen.dart';
import 'managed_jobs_list_screen.dart';
import 'managed_courses_list_screen.dart';
import '../../widgets/rive_loading_indicator.dart';

const Color neumorphicBackgroundColor = Color(0xFFF5F6FA);

// ===================================================================
// 1. الشاشة الرئيسية (StatefulWidget)
// ===================================================================
class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});
  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ManagedCompanyProvider>(context, listen: false).fetchManagedCompany(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = context.watch<ManagedCompanyProvider>();
    final theme = Theme.of(context);
    final int notificationCount = companyProvider.company?.newApplicantsCount ?? 0;

    return Scaffold(
      backgroundColor: neumorphicBackgroundColor,
      appBar: AppBar(
        backgroundColor: neumorphicBackgroundColor,
        elevation: 0,
        title: Text(
          companyProvider.company?.name ?? 'لوحة التحكم',
          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: theme.primaryColor),
        actions: [
          IconButton(
            tooltip: 'الإشعارات',
            icon: Badge(
              label: Text(notificationCount.toString()),
              isLabelVisible: notificationCount > 0,
              backgroundColor: theme.colorScheme.secondary,
              child: const Icon(Icons.notifications_none_outlined),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagedJobsListScreen())),
          ),
        ],
      ),
      drawer: const _ManagerDrawer(),
      body: _buildBody(context, companyProvider),
    );
  }

  Widget _buildBody(BuildContext context, ManagedCompanyProvider provider) {
    if (provider.isLoading) return const Center(child: RiveLoadingIndicator());
    if (provider.hasCompany) return _DashboardView(company: provider.company!);
    return const _RequestCompanyView();
  }
}

// ===================================================================
// 2. واجهة لوحة التحكم (عند وجود شركة)
// ===================================================================
class _DashboardView extends StatelessWidget {
  final Company company;
  const _DashboardView({required this.company});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => Provider.of<ManagedCompanyProvider>(context, listen: false).fetchManagedCompany(context),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company.name ?? 'شركتك',
                style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'أهلاً بك في لوحة التحكم الخاصة بك',
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 30),

          // بطاقات الإحصائيات
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'الوظائف المفتوحة',
                  value: company.openJobsCount?.toString() ?? '0',
                  icon: Icons.work_outline,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagedJobsListScreen())),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _StatCard(
                  title: 'المتقدمون الجدد',
                  value: company.newApplicantsCount?.toString() ?? '0',
                  icon: Icons.people_alt_outlined,
                  hasNotification: (company.newApplicantsCount ?? 0) > 0,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagedJobsListScreen())),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 40),

          _ActionCard(
            title: 'إدارة الوظائف', icon: Icons.business_center_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagedJobsListScreen())),
          ).animate().fadeIn(delay: 600.ms),

          _ActionCard(
            title: 'إدارة الدورات', icon: Icons.school_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagedCoursesListScreen())),
          ).animate().fadeIn(delay: 700.ms),

          _ActionCard(
            title: 'إعدادات الشركة', icon: Icons.settings_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditCompanyScreen())),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }
}

// ===================================================================
// 3. ويدجت بطاقة الإحصائيات
// ===================================================================
class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final bool hasNotification;
  final VoidCallback? onTap;
  const _StatCard({required this.title, required this.value, required this.icon, this.hasNotification = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 28),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          if (hasNotification)
            Positioned(
              top: -8, right: -8,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

// ===================================================================
// 4. ويدجت بطاقة الإجراءات
// ===================================================================
class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: NeumorphicContainer(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(width: 20),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// 5. واجهة طلب إنشاء شركة
// ===================================================================
class _RequestCompanyView extends StatelessWidget {
  const _RequestCompanyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const NeumorphicContainer(isCircle: true, padding: EdgeInsets.all(24), child: Icon(Icons.add_business_outlined, size: 80, color: Colors.grey)),
            const SizedBox(height: 32),
            Text('ابدأ بإضافة شركتك', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('لا يوجد ملف شركة مرتبط بحسابك حالياً. يمكنك تقديم طلب الآن ليتم مراجعته.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700, height: 1.5)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCompanyRequestScreen())),
              child: const Text('قدم طلب الآن'),
            )
          ],
        ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
      ),
    );
  }
}

// ===================================================================
// 6. الويدجت الأساسية لتصميم Neumorphism
// ===================================================================
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isCircle;
  final EdgeInsets padding;

  const NeumorphicContainer({Key? key, required this.child, this.onTap, this.isCircle = false, this.padding = const EdgeInsets.all(20)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: neumorphicBackgroundColor,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(4, 4), blurRadius: 15),
            BoxShadow(color: Colors.white.withOpacity(0.9), offset: const Offset(-4, -4), blurRadius: 15),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ===================================================================
// 7. ويدجت الشريط الجانبي الزجاجي
// ===================================================================
class _ManagerDrawer extends StatelessWidget {
  const _ManagerDrawer();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final theme = Theme.of(context);

    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerHeader(user, theme),
                      _MenuItem(
                        icon: Icons.person_outline,
                        title: 'الملف الشخصي',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
                      ),
                      _MenuItem(
                        icon: Icons.settings_outlined,
                        title: 'إعدادات الشركة',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditCompanyScreen())),
                      ),
                    ].animate(interval: 100.ms).fadeIn(duration: 400.ms).slideX(begin: 0.5),
                  ),
                ),
                const Divider(color: Colors.black26, indent: 20, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _MenuItem(
                    icon: Icons.logout,
                    title: 'تسجيل الخروج',
                    isLogout: true,
                    onTap: () => authProvider.logout(),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(User? user, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: CircleAvatar(
              radius: 37,
              backgroundColor: theme.primaryColor,
              child: Text(user?.firstName?.substring(0, 1).toUpperCase() ?? 'M', style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Text('${user?.firstName} ${user?.lastName}', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.3);
  }
}

// ===================================================================
// 8. ويدجت عنصر القائمة المتوهج
// ===================================================================
class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;
  const _MenuItem({Key? key, required this.icon, required this.title, required this.onTap, this.isLogout = false}) : super(key: key);

  @override
  __MenuItemState createState() => __MenuItemState();
}

class __MenuItemState extends State<_MenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isLogout ? Colors.red.shade400 : theme.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 250), widget.onTap);
        },
        child: AnimatedContainer(
          duration: 250.ms,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isHovered ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
            boxShadow: _isHovered ? [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: -5)] : [],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: color, size: 24),
              const SizedBox(width: 16),
              Text(widget.title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
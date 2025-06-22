// lib/screens/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/skill.dart';

// -- ويدجت Neumorphism الداكنة --
class DarkNeumorphicContainer extends StatelessWidget {
  final Widget child;
  final bool isConcave;
  final EdgeInsets padding;
  final BoxShape shape;
  final VoidCallback? onTap;

  const DarkNeumorphicContainer({
    Key? key, required this.child, this.isConcave = false,
    this.padding = const EdgeInsets.all(12), this.shape = BoxShape.rectangle, this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF2E3239);
    final shadowColor = const Color(0xFF23262B);
    final lightColor = const Color(0xFF393D47);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(20) : null,
          shape: shape,
          gradient: isConcave ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [shadowColor, lightColor]) : null,
          boxShadow: isConcave ? null : [
            BoxShadow(color: shadowColor, offset: const Offset(5, 5), blurRadius: 10),
            BoxShadow(color: lightColor, offset: const Offset(-5, -5), blurRadius: 10),
          ],
        ),
        child: child,
      ),
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isEditMode = false;
  bool _isSaving = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _personalBioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _phoneController.text = user.phone ?? '';
      _personalBioController.text = user.profile?.personalDescription ?? '';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeControllers();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _personalBioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // ... منطق الحفظ
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF2E3239);
    const primaryColor = Color(0xFF00BFFF);
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(backgroundColor: backgroundColor, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: const BackButton(color: Colors.white70),
        title: const Text('الملف الشخصي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)))
          else
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: DarkNeumorphicContainer(
                onTap: () {
                  if (_isEditMode) _saveProfile();
                  else setState(() => _isEditMode = true);
                },
                shape: BoxShape.circle,
                padding: const EdgeInsets.all(12),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    _isEditMode ? Icons.save_alt_rounded : Icons.edit_rounded,
                    key: ValueKey<bool>(_isEditMode),
                    color: primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildHeader(user, primaryColor),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: _isEditMode ? _buildEditView(key: const ValueKey('edit')) : _buildDisplayView(user: user, key: const ValueKey('display')),
            ),
          ],
        ),
      ),
    );
  }

  // --- واجهات العرض والتعديل ---
  Widget _buildDisplayView({required User user, Key? key}) {
    return Column(
      key: key,
      children: [
        _buildInfoSection(title: 'المعلومات الأساسية', children: [
          _buildInfoRow(Icons.email_outlined, user.email ?? '...'),
          const Divider(height: 24, color: Colors.white10),
          _buildInfoRow(Icons.phone_outlined, user.phone ?? '...'),
        ]),
        const SizedBox(height: 24),
        _buildInfoSection(title: 'النبذة التعريفية', children: [
          Text(user.profile?.personalDescription ?? 'لم تتم إضافة نبذة.', style: const TextStyle(color: Colors.white70, height: 1.5)),
        ]),
        const SizedBox(height: 24),
        _buildInfoSection(title: 'المهارات', children: [
          _buildSkillsView(user.skills ?? []),
        ]),
      ],
    );
  }

  Widget _buildEditView({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildInfoSection(title: 'تعديل المعلومات', children: [
          _buildTextFormField(_firstNameController, 'الاسم الأول'),
          const SizedBox(height: 16),
          _buildTextFormField(_lastNameController, 'الاسم الأخير'),
          const SizedBox(height: 16),
          _buildTextFormField(_phoneController, 'رقم الهاتف', keyboardType: TextInputType.phone),
        ]),
        const SizedBox(height: 24),
        _buildInfoSection(title: 'تعديل النبذة', children: [
          _buildTextFormField(_personalBioController, 'نبذة شخصية', maxLines: 5),
        ]),
      ],
    );
  }

  // --- ويدجت مساعدة ---
  Widget _buildHeader(User user, Color primaryColor) {
    return DarkNeumorphicContainer(
      isConcave: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          DarkNeumorphicContainer(
            shape: BoxShape.circle,
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.transparent,
              child: Text(user.firstName?.substring(0, 1) ?? 'U', style: TextStyle(color: primaryColor, fontSize: 32, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(user.type ?? 'غير محدد', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({required String title, required List<Widget> children}) {
    return DarkNeumorphicContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSkillsView(List<Skill> skills) {
    if (skills.isEmpty) return const Text('لم تتم إضافة مهارات بعد.', style: TextStyle(color: Colors.white54));
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: skills.map((skill) => DarkNeumorphicContainer(
        onTap: () {},
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(skill.name ?? '', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
      )).toList(),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54),
        const SizedBox(width: 16),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white70))),
      ],
    );
  }

  // --- هنا تم تصحيح تعريف الدالة ---
  Widget _buildTextFormField(
      TextEditingController controller,
      String label,
      { // استخدام الأقواس المعقوفة للبارامترات المسماة
        int maxLines = 1,
        TextInputType? keyboardType,
      }
      ) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF23262B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
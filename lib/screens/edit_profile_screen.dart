// lib/screens/profile/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../models/skill.dart';
import '../../providers/public_skill_provider.dart';
import 'user_profile_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final User userToEdit;
  const EditProfileScreen({super.key, required this.userToEdit});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _personalDescController = TextEditingController();
  final _universityController = TextEditingController();
  final _gpaController = TextEditingController();

  List<Skill> _allSkills = [];
  List<Skill> _selectedSkills = [];
  bool _isLoadingSkills = true;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.userToEdit.firstName ?? '';
    _lastNameController.text = widget.userToEdit.lastName ?? '';
    _phoneController.text = widget.userToEdit.phone ?? '';
    _personalDescController.text = widget.userToEdit.profile?.personalDescription ?? '';
    _universityController.text = widget.userToEdit.profile?.university ?? '';
    _gpaController.text = widget.userToEdit.profile?.gpa ?? '';

    if (widget.userToEdit.skills != null) {
      _selectedSkills = List<Skill>.from(widget.userToEdit.skills!);
    }
    _fetchAvailableSkills();
  }

  Future<void> _fetchAvailableSkills() async {
    try {
      final skillProvider = Provider.of<PublicSkillProvider>(context, listen: false);
      // تم تعديل الاستدعاء ليتوافق مع Provider
      await skillProvider.fetchSkills();
      if (mounted) {
        setState(() {
          _allSkills = skillProvider.skills;
          _isLoadingSkills = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSkills = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _personalDescController.dispose();
    _universityController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final Map<String, dynamic> profileData = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'personal_description': _personalDescController.text.trim(),
      'university': _universityController.text.trim(),
      'gpa': _gpaController.text.trim(),
    };

    try {
      await authProvider.updateUserProfile(profileData);
      final List<int> selectedSkillIds = _selectedSkills.map((s) => s.skillId!).toList();
      await authProvider.syncUserSkills(selectedSkillIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحديث: ${e.message}'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        backgroundColor: Colors.transparent,
        foregroundColor: theme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: _saveProfile,
            tooltip: 'حفظ التغييرات',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- تطبيق الحركات على كل قسم على حدة ---
              _buildSectionTitle(theme, "المعلومات الشخصية"),
              const SizedBox(height: 8),
              _buildInfoCard(
                children: [
                  _buildTextFormField(controller: _firstNameController, labelText: 'الاسم الأول', icon: Icons.person_outline),
                  const Divider(indent: 50, height: 1),
                  _buildTextFormField(controller: _lastNameController, labelText: 'الاسم الأخير', icon: Icons.person_outline),
                  const Divider(indent: 50, height: 1),
                  _buildTextFormField(controller: _phoneController, labelText: 'رقم الهاتف', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

              const SizedBox(height: 30),

              _buildSectionTitle(theme, "معلومات إضافية"),
              const SizedBox(height: 8),
              _buildInfoCard(
                children: [
                  _buildTextFormField(controller: _universityController, labelText: 'الجامعة', icon: Icons.school_outlined),
                  const Divider(indent: 50, height: 1),
                  _buildTextFormField(controller: _gpaController, labelText: 'المعدل التراكمي', icon: Icons.star_border_outlined, keyboardType: TextInputType.number),
                  const Divider(indent: 50, height: 1),
                  _buildTextFormField(controller: _personalDescController, labelText: 'النبذة التعريفية', icon: Icons.description_outlined, maxLines: 4),
                ],
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 30),

              _buildSectionTitle(theme, "المهارات"),
              const SizedBox(height: 8),
              _buildInfoCard(
                children: [
                  _isLoadingSkills
                      ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
                      : _allSkills.isEmpty
                      ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('لا توجد مهارات متاحة')))
                      : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _allSkills.map((skill) {
                        final bool isSelected = _selectedSkills.any((s) => s.skillId == skill.skillId);
                        return ChoiceChip(
                          label: Text(skill.name ?? ''),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSkills.add(skill);
                              } else {
                                _selectedSkills.removeWhere((s) => s.skillId == skill.skillId);
                              }
                            });
                          },
                          selectedColor: theme.primaryColor,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                          backgroundColor: Colors.grey.shade200,
                          side: BorderSide(color: Colors.grey.shade300),
                          pressElevation: 0,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

              const SizedBox(height: 40),

              Center(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return authProvider.isLoading
                        ? const CircularProgressIndicator()
                        : NeumorphicButton(
                      onTap: _saveProfile,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 60),
                      child: Text(
                        'حفظ التغييرات',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.elasticOut);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, right: 8),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return NeumorphicCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: labelText,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.7)),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
      validator: (value) {
        if (labelText != 'رقم الهاتف' && (value == null || value.trim().isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }
}
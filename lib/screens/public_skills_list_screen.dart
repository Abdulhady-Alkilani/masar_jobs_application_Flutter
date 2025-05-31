import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/public_skill_provider.dart';
import '../models/skill.dart';

class PublicSkillsListScreen extends StatefulWidget {
  const PublicSkillsListScreen({Key? key}) : super(key: key);

  @override
  _PublicSkillsListScreenState createState() => _PublicSkillsListScreenState();
}

class _PublicSkillsListScreenState extends State<PublicSkillsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  // يمكنك استخدام Debouncer هنا لتجنب إرسال طلب بحث مع كل حرف

  @override
  void initState() {
    super.initState();
    // جلب جميع المهارات عند البدء
    Provider.of<PublicSkillProvider>(context, listen: false).fetchSkills();

    // إضافة مستمع لحقل البحث (اختياري: استخدم Debouncer)
    _searchController.addListener(() {
      // جلب المهارات مع بارامتر البحث بعد فترة قصيرة من التوقف عن الكتابة
      Provider.of<PublicSkillProvider>(context, listen: false).fetchSkills(searchTerm: _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final skillProvider = Provider.of<PublicSkillProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المهارات'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'بحث عن مهارة',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
          ),
          Expanded( // لتوسيع قائمة المهارات لتأخذ المساحة المتبقية
            child: skillProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : skillProvider.error != null
                ? Center(child: Text('Error: ${skillProvider.error}'))
                : skillProvider.skills.isEmpty
                ? const Center(child: Text('لا توجد مهارات مطابقة.'))
                : ListView.builder(
              itemCount: skillProvider.skills.length,
              itemBuilder: (context, index) {
                final skill = skillProvider.skills[index];
                return ListTile(
                  title: Text(skill.name ?? 'بدون اسم'),
                  // يمكنك إضافة أيقونة أو تفاصيل أخرى
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
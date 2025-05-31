import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/public_group_provider.dart';
import '../models/group.dart';
import 'package:url_launcher/url_launcher.dart'; // لتشغيل الروابط

class PublicGroupsListScreen extends StatefulWidget {
  const PublicGroupsListScreen({Key? key}) : super(key: key);

  @override
  _PublicGroupsListScreenState createState() => _PublicGroupsListScreenState();
}

class _PublicGroupsListScreenState extends State<PublicGroupsListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<PublicGroupProvider>(context, listen: false).fetchGroups();
  }

  // تابع لفتح الرابط
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }


  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<PublicGroupProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المجموعات'),
      ),
      body: groupProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupProvider.error != null
          ? Center(child: Text('Error: ${groupProvider.error}'))
          : groupProvider.groups.isEmpty
          ? const Center(child: Text('لا توجد مجموعات متاحة حالياً.'))
          : ListView.builder(
        itemCount: groupProvider.groups.length,
        itemBuilder: (context, index) {
          final group = groupProvider.groups[index];
          return ListTile(
            title: Text(group.telegramHyperLink ?? 'رابط غير معروف'),
            leading: const Icon(Icons.link),
            onTap: () {
              // فتح رابط المجموعة عند النقر
              if (group.telegramHyperLink != null) {
                _launchUrl(group.telegramHyperLink!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لا يوجد رابط لهذه المجموعة')),
                );
              }
            },
          );
        },
      ),
    );
  }
}
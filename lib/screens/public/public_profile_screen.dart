import 'package:flutter/material.dart';
import 'package:masar_jobs/models/profile.dart';
import 'package:masar_jobs/models/skill.dart';
import 'package:masar_jobs/models/user.dart';
import 'package:masar_jobs/services/api_service.dart';
import 'package:masar_jobs/widgets/skill_chip.dart';
import 'package:transparent_image/transparent_image.dart';
import '../../widgets/rive_loading_indicator.dart';

class PublicProfileScreen extends StatefulWidget {
  final int userId;

  const PublicProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = ApiService().getUserById(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(color: Colors.black)),
      ),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RiveLoadingIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('لم يتم العثور على المستخدم'));
          }

          final user = snapshot.data!;
          final profile = user.profile;
          final userSkills = user.skills ?? [];

          return Column(
            children: [
              // Cover Photo and Profile Picture Section
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Theme.of(context).primaryColor.withOpacity(0.3), // Placeholder for cover photo
                    child: (profile?.coverPhoto != null && profile!.coverPhoto!.isNotEmpty)
                        ? FadeInImage.memoryNetwork(
                            placeholder: kTransparentImage,
                            image: profile.coverPhoto!,
                            fit: BoxFit.cover,
                            imageErrorBuilder: (context, error, stackTrace) =>
                                Image.asset('assets/image/default_cover.png', fit: BoxFit.cover), // Default cover
                          )
                        : Image.asset('assets/image/default_cover.png', fit: BoxFit.cover), // Default cover
                  ),
                  Positioned(
                    bottom: -60, // Adjust to overlap cover photo
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      child: CircleAvatar(
                        radius: 56,
                        backgroundImage: (user.photo != null && user.photo!.isNotEmpty)
                            ? NetworkImage(user.photo!)
                            : null,
                        child: (user.photo == null || user.photo!.isEmpty)
                            ? Icon(Icons.person, size: 60, color: Theme.of(context).primaryColor)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 70), // Space for the overlapping avatar
              Text(
                '${user.firstName ?? ''} ${user.lastName ?? ''}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (profile?.jobTitle != null)
                Text(
                  profile!.jobTitle!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              const SizedBox(height: 16),
              // Like Page Button and Count (Placeholder)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement like/unlike functionality for the page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Like Page functionality coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.thumb_up_alt_outlined),
                    label: const Text('Like Page'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '1.2K Likes', // Placeholder for actual like count
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                      _buildSectionTitle(context, 'نبذة تعريفية'),
                      const SizedBox(height: 8),
                      Text(
                        profile.bio!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionTitle(context, 'المهارات'),
                    const SizedBox(height: 8),
                    if (userSkills.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: userSkills.map((skill) => SkillChip(skill: skill)).toList(),
                      )
                    else
                      const Text('لا توجد مهارات لعرضها'),
                    const SizedBox(height: 24),
                    if (profile != null)
                      _buildAdditionalInfo(context, profile),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user, Profile? profile) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: (user.photo != null && user.photo!.isNotEmpty)
              ? NetworkImage(user.photo!)
              : null,
          child: (user.photo == null || user.photo!.isEmpty)
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user.firstName ?? ''} ${user.lastName ?? ''}',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              if (profile?.jobTitle != null)
                Text(
                  profile!.jobTitle!,
                  style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, Profile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'معلومات إضافية'),
        const SizedBox(height: 8),
        if (profile.city != null || profile.country != null)
          _buildInfoRow(Icons.location_on, '${profile.city ?? ''}, ${profile.country ?? ''}'),
        if (profile.website != null)
          _buildInfoRow(Icons.link, profile.website!),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}


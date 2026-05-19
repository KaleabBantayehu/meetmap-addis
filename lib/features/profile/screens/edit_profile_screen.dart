import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/profile_image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool isPrivateProfile = true;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Selamawit T.');
    _emailController = TextEditingController(text: 'selam.t@meetmap.et');
    _phoneController = TextEditingController(text: '+251 911 234 567');
    _bioController = TextEditingController(
      text: 'Marketing Strategist & Tech Enthusiast based in Bole. Love connecting with fellow professionals and exploring the hidden cafe gems of Addis Ababa.',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Implement save logic
              Navigator.of(context).pop();
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const ProfileImagePicker(
              imageUrl: 'https://i.pravatar.cc/300?img=47',
            ),
            const SizedBox(height: 32),
            LabeledTextField(
              label: 'Full Name',
              hintText: 'Enter your full name',
              controller: _nameController,
            ),
            LabeledTextField(
              label: 'Email Address',
              hintText: 'Enter your email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            LabeledTextField(
              label: 'Phone Number',
              hintText: 'Enter your phone number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            LabeledTextField(
              label: 'Bio',
              hintText: 'Tell us about yourself',
              controller: _bioController,
              maxLines: 4,
            ),
            const Divider(height: 40),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Private Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Only your connections can see your details.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isPrivateProfile,
                  onChanged: (val) => setState(() => isPrivateProfile = val),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 60),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // TODO: Implement deactivate logic
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                label: const Text(
                  'Deactivate Account',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

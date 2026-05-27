import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/core/services/cloudinary_service.dart';
import 'package:meetmap_addis/providers/auth_provider.dart';
import 'package:meetmap_addis/shared/models/user_model.dart';
import 'package:provider/provider.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/profile_image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool isPrivateProfile = true;
  bool _isUploadingImage = false;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
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
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

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
            onPressed: user == null || authProvider.isLoading
                ? null
                : () => _saveProfile(context, user),
            child: Text(
              authProvider.isLoading ? 'Saving' : 'Save',
              style: TextStyle(
                color: user == null
                    ? AppColors.textSecondary
                    : AppColors.primary,
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
            ProfileImagePicker(
              imageUrl: user?.profileImageUrl ?? '',
              onPickImage: user == null || _isUploadingImage
                  ? null
                  : () => _changeProfileImage(user),
            ),
            if (_isUploadingImage) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
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
                  activeTrackColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 60),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // TODO: Implement deactivate logic
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
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

  Future<void> _saveProfile(BuildContext context, UserModel user) async {
    final updatedUser = user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
    );
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(updatedUser);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Profile updated.'
              : authProvider.errorMessage ?? 'Failed to update profile.',
        ),
        backgroundColor: success ? AppColors.primary : AppColors.error,
      ),
    );
    if (success) Navigator.of(context).pop();
  }

  Future<void> _changeProfileImage(UserModel user) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    setState(() => _isUploadingImage = true);
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();

    try {
      final imageUrl = await _cloudinaryService.uploadImage(
        File(picked.path),
        'meetmap/profiles',
      );

      final success = await authProvider.updateProfile(
        user.copyWith(profileImageUrl: imageUrl),
      );
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile photo updated.'
                : authProvider.errorMessage ?? 'Failed to update profile photo.',
          ),
          backgroundColor: success ? AppColors.primary : AppColors.error,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      messenger.showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? 'Unable to upload image.' : message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/core/services/cloudinary_service.dart';
import 'package:meetmap_addis/core/storage/connectivity_service.dart';
import 'package:meetmap_addis/shared/models/hangout_model.dart';
import 'package:meetmap_addis/providers/hangouts_provider.dart';
import 'package:meetmap_addis/shared/widgets/custom_textfield.dart';
import 'package:meetmap_addis/shared/widgets/custom_button.dart';

class AddHangoutScreen extends StatefulWidget {
  const AddHangoutScreen({super.key});

  @override
  State<AddHangoutScreen> createState() => _AddHangoutScreenState();
}

class _AddHangoutScreenState extends State<AddHangoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _participantLimitController = TextEditingController();

  String _selectedCategory = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _selectedImage;

  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isUploading = false;
  bool _isSubmitting = false;

  static const List<String> _categories = ['Study', 'Coffee', 'Date', 'Business', 'Social'];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _participantLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  String _formatDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDay time) => time.format(context);

  Future<void> _submit() async {
    if (_isUploading || _isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory.isEmpty) {
      _showError('Please select a category');
      return;
    }
    if (_selectedImage == null) {
      _showError('Please upload an image');
      return;
    }
    if (_descriptionController.text.trim().length < 20) {
      _showError('Description must be at least 20 characters');
      return;
    }
    if (_selectedDate == null) {
      _showError('Please select a date');
      return;
    }
    if (_selectedTime == null) {
      _showError('Please select a time');
      return;
    }
    if (!ConnectivityService.instance.isConnected) {
      _showError('Internet connection required');
      return;
    }

    setState(() => _isUploading = true);

    final provider = context.read<HangoutsProvider>();
    try {
      final imageUrl = await _cloudinaryService.uploadImage(
        _selectedImage!,
        'meetmap/hangouts',
      );
      if (!mounted) return;
      setState(() => _isUploading = false);

      final newHangout = HangoutModel(
        id: '',
        title: _titleController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        time: _formatTime(_selectedTime!),
        imageUrl: imageUrl,
        attendeeCount: 1,
        description: _descriptionController.text.trim(),
      );

      setState(() => _isSubmitting = true);
      final success = await provider.addHangout(newHangout);
      if (!mounted) return;

      if (success) {
        _showSuccess('Hangout created successfully');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        _showError(provider.errorMessage ?? 'Failed to create hangout');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Upload failed: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _isSubmitting = false;
      });
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.error),
  );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Hangout'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageUploadSection(),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _titleController,
                hintText: 'Hangout Title',
                validator: (v) => v?.isEmpty ?? true ? 'Title required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _locationController,
                hintText: 'Location',
                validator: (v) => v?.isEmpty ?? true ? 'Location required' : null,
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _participantLimitController,
                hintText: 'Participant Limit (optional)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildDateTimeSection(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Description required';
                  if (v!.trim().length < 20) return 'At least 20 characters';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Description',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: _isUploading || _isSubmitting ? 'Creating...' : 'Create Hangout',
                onPressed: (_isUploading || _isSubmitting) ? null : _submit,
                isLoading: _isUploading || _isSubmitting,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline),
        ),
        child: _selectedImage == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    Text('Tap to add image', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : Image.file(_selectedImage!, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
      items: _categories
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (val) => setState(() => _selectedCategory = val ?? ''),
      decoration: InputDecoration(
        hintText: 'Category',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) => v?.isEmpty ?? true ? 'Select a category' : null,
    );
  }

  Widget _buildDateTimeSection() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _isUploading ? null : _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: 'Date',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              child: Text(
                _selectedDate == null ? 'Select date' : _formatDate(_selectedDate!),
                style: TextStyle(
                  color: _selectedDate == null ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _isUploading ? null : _pickTime,
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: 'Time',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              child: Text(
                _selectedTime == null ? 'Select time' : _formatTime(_selectedTime!),
                style: TextStyle(
                  color: _selectedTime == null ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

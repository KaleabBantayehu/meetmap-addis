import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/core/services/cloudinary_service.dart';
import 'package:meetmap_addis/core/storage/connectivity_service.dart';
import 'package:meetmap_addis/shared/models/event_model.dart';
import 'package:meetmap_addis/providers/events_provider.dart';
import 'package:meetmap_addis/shared/widgets/custom_textfield.dart';
import 'package:meetmap_addis/shared/widgets/custom_button.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = '';
  String _selectedPriceLevel = 'Free';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _selectedImage;

  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isUploading = false;
  bool _isSubmitting = false;

  static const List<String> _categories = [
    'Tech', 'Networking', 'Coffee', 'Music', 'Startup', 'Community', 'Study','Sports'
  ];
  static const List<String> _priceLevels = ['Free', 'Budget', 'Moderate', 'Premium'];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
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

    final provider = context.read<EventsProvider>();
    try {
      final imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);
      if (!mounted) return;
      setState(() => _isUploading = false);

      final newEvent = EventModel(
        id: '',
        title: _titleController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        date: _formatDate(_selectedDate!),
        time: _formatTime(_selectedTime!),
        host: 'Me',
        imageUrl: imageUrl,
        attendeeCount: 1,
        description: _descriptionController.text.trim(),
      );

      setState(() => _isSubmitting = true);
      final success = await provider.addEvent(newEvent);
      if (!mounted) return;

      if (success) {
        _showSuccess('Event created successfully');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        _showError(provider.errorMessage ?? 'Failed to create event');
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
        title: const Text('Create Event'),
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
                hintText: 'Event Title',
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
              _buildPriceLevelDropdown(),
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
                text: _isUploading || _isSubmitting ? 'Creating...' : 'Create Event',
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
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          'Select Category',
          style: TextStyle(
            color: AppColors.textSecondary, 
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      // FormField wrapper preserves your validator logic cleanly inside the form
      FormField<String>(
        validator: (value) => _selectedCategory.isEmpty ? 'Please select a category' : null,
        builder: (FormFieldState<String> state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.0,    // Horizontal gap between chips on the same line
                runSpacing: 8.0, // Vertical gap between lines
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  
                  return FractionallySizedBox(
                    // 0.31 means ~3 items per row with gaps accounted for. 
                    // Change to 0.47 if you prefer exactly 2 items per row.
                    widthFactor: 0.31, 
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundColor: AppColors.surface,
                      showCheckmark: false, // Hides checkmark to maximize text width room
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : '';
                          state.didChange(_selectedCategory); // Updates form validator state
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  key: const Key('category_error_msg'),
                  child: Text(
                    state.errorText ?? '',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
  Widget _buildPriceLevelDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedPriceLevel,
      items: _priceLevels
          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
          .toList(),
      onChanged: (val) => setState(() => _selectedPriceLevel = val ?? 'Free'),
      decoration: InputDecoration(
        hintText: 'Price Level',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
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

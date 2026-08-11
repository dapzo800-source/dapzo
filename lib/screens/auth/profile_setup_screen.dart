import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/validators.dart';
import '../../state/app_state.dart';
import 'package:provider/provider.dart';
import 'mode_selection_screen.dart';

/// Collects Name / Email / Date of Birth / (optional) Photo for a user.
/// Phone number is NOT re-asked here — it already comes from Firebase Auth.
class ProfileSetupScreen extends StatefulWidget {
  final bool isEditing;
  const ProfileSetupScreen({super.key, this.isEditing = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _dob;
  bool _loading = false;

  // Profile photo is optional. _pickedImage holds a freshly picked local
  // file; _existingImageUrl holds whatever is already saved (edit mode).
  // If the user removes the photo, _photoRemoved is set and no image is
  // uploaded/kept even if _existingImageUrl was non-empty.
  File? _pickedImage;
  String? _existingImageUrl;
  bool _photoRemoved = false;

  final _authService = AuthService();
  final _cloudinaryService = CloudinaryService();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = context.read<AppState>().user;
        if (user != null) {
          _nameController.text = user.name;
          _emailController.text = user.email;
          _dob = user.dateOfBirth;
          _existingImageUrl = user.profileImage.isNotEmpty ? user.profileImage : null;
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _showPhotoOptions() async {
    final hasPhoto = _pickedImage != null || (_existingImageUrl?.isNotEmpty ?? false);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    setState(() {
                      _pickedImage = null;
                      _existingImageUrl = null;
                      _photoRemoved = true;
                    });
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return;
      setState(() {
        _pickedImage = File(picked.path);
        _photoRemoved = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $source: $e')),
      );
    }
  }

  /// Uploads the picked photo to Cloudinary (unsigned upload, 'profiles'
  /// folder) and returns the resulting secure URL. Returns '' if the photo
  /// was removed, or the existing URL if the photo was never touched.
  Future<String> _resolvePhotoUrl() async {
    if (_photoRemoved) return '';
    if (_pickedImage == null) return _existingImageUrl ?? '';

    final url = await _cloudinaryService.uploadImage(_pickedImage!, folder: 'profiles');
    if (url == null) {
      throw Exception('Photo upload failed. Please try again.');
    }
    return url;
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final photoUrl = await _resolvePhotoUrl();

      final profile = UserModel(
        uid: user.uid,
        phone: user.phoneNumber ?? '',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        dateOfBirth: _dob,
        profileImage: photoUrl,
      );

      await _authService.createUserProfile(profile);

      if (!mounted) return;

      // Sync the newly saved profile into app-wide state so screens
      // like ProfileScreen immediately reflect the update.
      context.read<AppState>().setUser(profile);

      if (widget.isEditing) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ModeSelectionScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider;
    if (_pickedImage != null) {
      imageProvider = FileImage(_pickedImage!);
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_existingImageUrl!);
    }

    return Center(
      child: GestureDetector(
        onTap: _showPhotoOptions,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 44, color: AppColors.primary)
                  : null,
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.textSecondary.withOpacity(0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isEditing
          ? AppBar(title: const Text('Edit Profile'), elevation: 0)
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isEditing) ...[
                  Text('Complete Your Profile', style: AppTextStyles.heading),
                  const SizedBox(height: 8),
                  Text("Let's get your Dapzo account ready.", style: AppTextStyles.supporting),
                  const SizedBox(height: 28),
                ],
                _buildAvatar(),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Photo (optional)',
                    style: AppTextStyles.supporting.copyWith(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Full Name', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  validator: Validators.name,
                  decoration: _fieldDecoration('Enter your full name'),
                ),
                const SizedBox(height: 18),
                Text('Email', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  decoration: _fieldDecoration('you@example.com'),
                ),
                const SizedBox(height: 18),
                Text('Date of Birth', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickDob,
                  child: InputDecorator(
                    decoration: _fieldDecoration('DD / MM / YYYY').copyWith(
                      suffixIcon: const Icon(Icons.calendar_today_outlined,
                          color: AppColors.textSecondary, size: 20),
                    ),
                    child: Text(
                      _dob == null
                          ? 'DD / MM / YYYY'
                          : '${_dob!.day.toString().padLeft(2, '0')} / ${_dob!.month.toString().padLeft(2, '0')} / ${_dob!.year}',
                      style: AppTextStyles.body,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _loading ? null : _continue,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.isEditing ? 'Save Changes' : 'Continue',
                            style: AppTextStyles.button),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
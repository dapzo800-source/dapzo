import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../home/home_screen.dart';

/// Collects Name / Email / Date of Birth for a brand-new user.
/// Phone number is NOT re-asked here — it already comes from Firebase Auth.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _dob;
  bool _loading = false;

  final _authService = AuthService();

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

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser!;
    final profile = UserModel(
      uid: user.uid,
      phone: user.phoneNumber ?? '',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      dateOfBirth: _dob,
    );

    await _authService.createUserProfile(profile);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Complete Your Profile', style: AppTextStyles.heading),
                const SizedBox(height: 8),
                Text("Let's get your Dapzo account ready.", style: AppTextStyles.supporting),
                const SizedBox(height: 28),
                Text('Full Name', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  validator: Validators.name,
                  decoration: const InputDecoration(hintText: 'Enter your full name'),
                ),
                const SizedBox(height: 18),
                Text('Email', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                ),
                const SizedBox(height: 18),
                Text('Date of Birth', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDob,
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Text(
                      _dob == null
                          ? 'DD / MM / YYYY'
                          : '${_dob!.day.toString().padLeft(2, '0')} / ${_dob!.month.toString().padLeft(2, '0')} / ${_dob!.year}',
                      style: AppTextStyles.body,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _continue,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Continue'),
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

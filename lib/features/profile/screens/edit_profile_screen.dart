import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _name.text = user?.name ?? '';
    _mobile.text = user?.mobileNumber ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await ref
        .read(authProvider.notifier)
        .updateProfile(
          name: _name.text.trim(),
          mobileNumber: _mobile.text.trim().isEmpty
              ? null
              : _mobile.text.trim(),
        );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update failed. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            children: [
              const SizedBox(height: 16),
              AppTextField(
                controller: _name,
                label: 'Full Name',
                prefix: const Icon(Icons.person_outline),
                validator: (v) =>
                    v != null && v.length >= 2 ? null : 'Name too short',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _mobile,
                label: 'Mobile Number (optional)',
                keyboardType: TextInputType.phone,
                prefix: const Icon(Icons.phone_outlined),
              ),
              const SizedBox(height: 32),
              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _save,
                        child: const Text('Save Changes'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

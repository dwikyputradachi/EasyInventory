import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController(text: '');
  final _emailController = TextEditingController(text: '');

  // ── Change Photo ───────────────────────────────────────
  void _onChangePhoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppColors.surface,
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Photo',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _bottomSheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              onTap: () {
                Navigator.pop(context);
                // TODO: implement camera picker
              },
            ),
            const SizedBox(height: 12),
            _bottomSheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                // TODO: implement gallery picker
              },
            ),
            const SizedBox(height: 12),
            _bottomSheetOption(
              icon: Icons.delete_outline,
              label: 'Remove Photo',
              color: AppColors.danger,
              onTap: () {
                Navigator.pop(context);
                // TODO: implement remove photo
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _bottomSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Set Password Dialog ────────────────────────────────
  void _onSetPassword() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    bool oldVisible = false;
    bool newVisible = false;
    bool confirmVisible = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Change Password',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogPasswordField(
                    controller: oldPassController,
                    label: 'Current Password',
                    isVisible: oldVisible,
                    onToggle: () =>
                        setDialogState(() => oldVisible = !oldVisible),
                  ),
                  const SizedBox(height: 12),
                  _dialogPasswordField(
                    controller: newPassController,
                    label: 'New Password',
                    isVisible: newVisible,
                    onToggle: () =>
                        setDialogState(() => newVisible = !newVisible),
                  ),
                  const SizedBox(height: 12),
                  _dialogPasswordField(
                    controller: confirmPassController,
                    label: 'Confirm New Password',
                    isVisible: confirmVisible,
                    onToggle: () =>
                        setDialogState(() => confirmVisible = !confirmVisible),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '• Min. 8 characters\n• Use letters and numbers',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (newPassController.text != confirmPassController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'New passwords do not match.',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }
                    if (newPassController.text.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password must be at least 8 characters.',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password changed successfully!',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo Section ──────────────────────────────────
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _onChangePhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Change photo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Form Fields ────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  label: 'Name',
                  controller: _nameController,
                  placeholder: 'Enter your full name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 4),
                _buildField(
                  label: 'Email',
                  controller: _emailController,
                  placeholder: 'Enter your email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: implement save profile API
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Profile saved!',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Password Management ────────────────────────────
          Container(
            color: AppColors.surface,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PASSWORD MANAGEMENT',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const Divider(height: 16, color: AppColors.background),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _onSetPassword,
                    icon: const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    label: const Text(
                      'Set Password',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textSecondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
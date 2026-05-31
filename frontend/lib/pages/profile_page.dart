import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameC = TextEditingController(text: 'Dwiky Putra Dachi');
  final emailC = TextEditingController(text: 'dwiky@email.com');

  String name = 'Dwiky Putra Dachi';
  String email = 'dwiky@email.com';
  bool isEditing = false;

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    super.dispose();
  }

  void _saveProfile() {
    setState(() {
      name = nameC.text.trim();
      email = emailC.text.trim();
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _changePhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          runSpacing: 12,
          children: [
            const Text(
              'Change Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            _sheetItem(Icons.camera_alt_outlined, 'Take Photo'),
            _sheetItem(Icons.photo_library_outlined, 'Choose from Gallery'),
            _sheetItem(Icons.delete_outline, 'Remove Photo', danger: true),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    final currentC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();

    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Use a strong password to keep your account secure.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _passwordField(
                    currentC,
                    'Current Password',
                    showCurrent,
                        () => setSheetState(() => showCurrent = !showCurrent),
                  ),
                  const SizedBox(height: 12),

                  _passwordField(
                    newC,
                    'New Password',
                    showNew,
                        () => setSheetState(() => showNew = !showNew),
                  ),
                  const SizedBox(height: 12),

                  _passwordField(
                    confirmC,
                    'Confirm Password',
                    showConfirm,
                        () => setSheetState(() => showConfirm = !showConfirm),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Password should contain at least 8 characters.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (newC.text.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password must be at least 8 characters'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                          return;
                        }

                        if (newC.text != confirmC.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password does not match'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password updated'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      child: const Text(
                        'Save Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _passwordField(
      TextEditingController controller,
      String hint,
      bool visible,
      VoidCallback toggle,
      ) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
  Widget _sheetItem(IconData icon, String text, {bool danger = false}) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color)),
      onTap: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      children: [
        _profileHeader(),
        const SizedBox(height: 20),

        _sectionTitle('Personal Info'),
        const SizedBox(height: 10),
        _personalInfoCard(),

        const SizedBox(height: 20),

        _sectionTitle('Security'),
        const SizedBox(height: 10),
        _menuTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: _changePassword,
        ),

        const SizedBox(height: 20),

        _sectionTitle('App Settings'),
        const SizedBox(height: 10),
        _budgetSettingTile(),

        const SizedBox(height: 24),

        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () {},
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _profileHeader() {
    return Card(
      elevation: 0,
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _changePhoto,
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 46, color: Colors.white),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.surface,
                      child: Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              email,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personalInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isEditing ? _editForm() : _infoView(),
      ),
    );
  }

  Widget _infoView() {
    return Column(
      children: [
        _infoRow(Icons.person_outline, 'Name', name),
        const Divider(),
        _infoRow(Icons.email_outlined, 'Email', email),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => isEditing = true),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
          ),
        ),
      ],
    );
  }

  Widget _editForm() {
    return Column(
      children: [
        TextField(
          controller: nameC,
          decoration: _input('Name', Icons.person_outline),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailC,
          decoration: _input('Email', Icons.email_outlined),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => isEditing = false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _budgetSettingTile() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SwitchListTile(
        value: false,
        onChanged: null,
        secondary: CircleAvatar(
          backgroundColor: AppColors.warning.withOpacity(0.12),
          child: const Icon(Icons.savings_outlined, color: AppColors.warning),
        ),
        title: const Text(
          'Enable Budget Recommendation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Coming soon: show monthly budget suggestion in statistics',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.10),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _input(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
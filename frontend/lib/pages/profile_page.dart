import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../data/app_data.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'package:quickalert/quickalert.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  File? profileImage;
  final _picker = ImagePicker();

  String name = '';
  String email = '';

  bool isEditing = false;
  bool isLoading = true;
  bool isSaving = false;
  bool budgetEnabled = true;

  @override
  void initState() {
    super.initState();
    name = AppData().name;
    email = AppData().email;
    nameC.text = name;
    emailC.text = email;
    budgetEnabled = AppData().budgetRecommendationEnabled;
    if (AppData().profileImagePath.isNotEmpty) {
      profileImage = File(AppData().profileImagePath);
    }
    _loadProfile();
  }

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    super.dispose();
  }

  // ---------- Data ----------

  Future<void> _loadProfile() async {
    final res = await ProfileService.getProfile();
    if (res['status'] == 'success') {
      final data = res['data'];
      setState(() {
        name = data['name'] ?? '';
        email = data['email'] ?? '';
        nameC.text = name;
        emailC.text = email;
        AppData().setProfilePhoto(data['profile_photo'] ?? '');
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      _snack(res['message'] ?? 'Failed to load profile', AppColors.danger);
    }
  }

  Future<void> _saveProfile() async {
    if (nameC.text.trim().isEmpty) {
      return _snack('Name is required', AppColors.warning);
    }

    setState(() => isSaving = true);
    
    final res = await ProfileService.updateProfile(
      name: nameC.text.trim(),
      email: email, 
    );

    setState(() => isSaving = false);

    if (res['status'] == 'success') {
      setState(() {
        name = nameC.text.trim();
        isEditing = false;
      });
 QuickAlert.show(
  context: context,
  type: QuickAlertType.success,
  title: 'Success',
  text: 'Profile updated successfully.',
);
    } else {
      _snack(res['message'] ?? 'Failed to update profile', AppColors.danger);
    }
  }

Future<void> _logout() async {
  final result = await QuickAlert.show(
    context: context,
    type: QuickAlertType.confirm,
    title: 'Logout',
    text: 'Are you sure you want to logout?',
    showCancelBtn: true,
    confirmBtnText: 'Logout',
    cancelBtnText: 'Cancel',
  );

  if (result == true) {
    AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (_) => false,
    );
  }
}

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // ---------- Photo (upload still local only, not yet persisted to DB record read-back) ----------

  Future<void> _pickProfileImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;

    setState(() => profileImage = File(picked.path));
    AppData().profileImagePath = picked.path;

    final res = await ProfileService.uploadPhoto(picked.path);
    _snack(
      res['status'] == 'success'
          ? 'Profile photo uploaded'
          : (res['message'] ?? 'Failed to upload photo'),
      res['status'] == 'success' ? AppColors.primary : AppColors.danger,
    );
  }

  void _changePhoto() {
    _showSheet(
      Wrap(
        runSpacing: 12,
        children: [
          const Text('Change Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          _sheetItem(Icons.camera_alt_outlined, 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.camera);
              }),
          _sheetItem(Icons.photo_library_outlined, 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.gallery);
              }),
          _sheetItem(Icons.delete_outline, 'Remove Photo', danger: true,
              onTap: () {
                Navigator.pop(context);
                setState(() => profileImage = null);
                AppData().profileImagePath = '';
                _snack('Profile photo removed', AppColors.danger);
              }),
        ],
      ),
      padding: const EdgeInsets.all(20),
    );
  }

  // ---------- Change Password ----------

  void _changePassword() {
    final currentC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();
    bool showCurrent = false, showNew = false, showConfirm = false, saving = false;

    _showSheet(
      StatefulBuilder(builder: (context, setSheetState) {
        Future<void> save() async {
          if (currentC.text.isEmpty || newC.text.isEmpty || confirmC.text.isEmpty) {
            return _snack('All password fields are required', AppColors.warning);
          }
          if (newC.text.length < 8) {
            return _snack('Password must be at least 8 characters', AppColors.warning);
          }
          if (newC.text != confirmC.text) {
            return _snack('Password does not match', AppColors.danger);
          }

          setSheetState(() => saving = true);
          final res = await ProfileService.changePassword(
            oldPassword: currentC.text,
            newPassword: newC.text,
          );
          setSheetState(() => saving = false);

          if (res['status'] == 'success') {
            Navigator.pop(context);
          QuickAlert.show(
  context: context,
  type: QuickAlertType.success,
  title: 'Success',
  text: 'Password updated successfully.',
);
          } else {
            _snack(res['message'] ?? 'Failed to update password', AppColors.danger);
          }
        }

        return _sheetScaffold(
          title: 'Change Password',
          subtitle: 'Use a strong password to keep your account secure.',
          children: [
            _passwordField(currentC, 'Current Password', showCurrent,
                () => setSheetState(() => showCurrent = !showCurrent)),
            const SizedBox(height: 12),
            _passwordField(newC, 'New Password', showNew,
                () => setSheetState(() => showNew = !showNew)),
            const SizedBox(height: 12),
            _passwordField(confirmC, 'Confirm Password', showConfirm,
                () => setSheetState(() => showConfirm = !showConfirm)),
            const SizedBox(height: 14),
            _infoBanner('Password should contain at least 8 characters.'),
            const SizedBox(height: 20),
            _primaryButton('Save Password', saving, save),
          ],
        );
      }),
    );
  }

  // ---------- Change Email: password -> new email -> OTP ----------

    void _changeEmail() {
      final passwordC = TextEditingController();
      final newEmailC = TextEditingController();
      final otpC = TextEditingController();
      bool showPassword = false;
      bool loading = false;
      int step = 0; 

      _showSheet(
        StatefulBuilder(builder: (context, setSheetState) {
          Future<void> verifyPassword() async {
            if (passwordC.text.isEmpty) {
              return _snack('Password is required', AppColors.warning);
            }
            setSheetState(() => loading = true);
            final res = await ProfileService.verifyPassword(passwordC.text);
            setSheetState(() => loading = false);

            if (res['status'] == 'success') {
              setSheetState(() => step = 1);
            } else {
              _snack(res['message'] ?? 'Incorrect password', AppColors.danger);
            }
          }

          Future<void> sendOtp() async {
            final newEmail = newEmailC.text.trim();
            if (newEmail.isEmpty || !newEmail.contains('@')) {
              return _snack('Enter a valid email', AppColors.warning);
            }
            setSheetState(() => loading = true);
            final res = await ProfileService.sendEmailChangeOtp(newEmail);
            setSheetState(() => loading = false);

            if (res['status'] == 'success') {
              setSheetState(() => step = 2);
            } else {
              _snack(res['message'] ?? 'Failed to send OTP', AppColors.danger);
            }
          }

          Future<void> verifyOtp() async {
            if (otpC.text.trim().isEmpty) {
              return _snack('OTP is required', AppColors.warning);
            }
            
            final targetEmail = newEmailC.text.trim();

            setSheetState(() => loading = true);
            final res = await ProfileService.verifyEmailChangeOtp(
              email: targetEmail, 
              otp: otpC.text.trim(),
            );
            setSheetState(() => loading = false);

            if (res['status'] == 'success') {
              Navigator.pop(context);
              setState(() {
                email = targetEmail; 
                emailC.text = targetEmail; 
              });
            QuickAlert.show(
  context: context,
  type: QuickAlertType.success,
  title: 'Success',
  text: 'Email updated successfully.',
);
            } else {
              _snack(res['message'] ?? 'Invalid or expired OTP', AppColors.danger);
            }
          }

          switch (step) {
            case 1:
              return _sheetScaffold(
                title: 'New Email',
                subtitle: 'We will send a verification code to this address.',
                children: [
                  TextField(
                    controller: newEmailC,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _input('New Email', Icons.email_outlined),
                  ),
                  const SizedBox(height: 20),
                  _primaryButton('Send OTP', loading, sendOtp),
                ],
              );
            case 2:
              return _sheetScaffold(
                title: 'Verify Email',
                subtitle: 'Enter the code sent to ${newEmailC.text.trim()}.',
                children: [
                  TextField(
                    controller: otpC,
                    keyboardType: TextInputType.number,
                    decoration: _input('OTP Code', Icons.pin_outlined),
                  ),
                  const SizedBox(height: 20),
                  _primaryButton('Verify & Update', loading, verifyOtp),
                ],
              );
            default:
              return _sheetScaffold(
                title: 'Change Email',
                subtitle: 'Confirm your account password to continue.',
                children: [
                  _passwordField(passwordC, 'Account Password', showPassword,
                      () => setSheetState(() => showPassword = !showPassword)),
                  const SizedBox(height: 20),
                  _primaryButton('Continue', loading, verifyPassword),
                ],
              );
          }
        }),
      );
    }

  void _showSheet(Widget child, {EdgeInsets? padding}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: padding ??
            EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
        child: child,
      ),
    );
  }

  Widget _sheetScaffold({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return ListView(
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
        Text(title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 18),
        ...children,
      ],
    );
  }

  Widget _infoBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, bool loading, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _sheetItem(IconData icon, String text, {bool danger = false, VoidCallback? onTap}) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color)),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

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
        const SizedBox(height: 10),
        _menuTile(
          icon: Icons.alternate_email,
          title: 'Change Email',
          subtitle: 'Update the email linked to your account',
          onTap: _changeEmail,
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
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Logout', style: TextStyle(color: Colors.white)),
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
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white24,
                    backgroundImage:
                         profileImage != null
                            ? FileImage(profileImage!)
                            : (AppData().profilePhoto.isNotEmpty
                                   ? NetworkImage(
                                      '${ApiService.baseUrl.replaceAll('/api', '')}/${AppData().profilePhoto}',
                                     )
                                   : null) as ImageProvider?,
                    child: profileImage == null &&
                             AppData().profilePhoto.isEmpty
                         ? const Icon(
                            Icons.person,
                             size: 46,
                             color: Colors.white,
                          )
                         : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.surface,
                      child: Icon(Icons.camera_alt, size: 14, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name.isNotEmpty ? name : 'User',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(email.isNotEmpty ? email : '-', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
          decoration: _input('Name', Icons.person_outline)
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving
                    ? null
                    : () {
                        nameC.text = name;
                        setState(() => isEditing = false);
                      },
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: isSaving ? null : _saveProfile,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save', style: TextStyle(color: Colors.white)),
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
        value: budgetEnabled,
        onChanged: (value) {
          setState(() => budgetEnabled = value);
          AppData().budgetRecommendationEnabled = value;
          _snack(
            value ? 'Budget recommendation enabled' : 'Budget recommendation disabled',
            AppColors.primary,
          );
        },
        secondary: CircleAvatar(
          backgroundColor: AppColors.warning.withOpacity(0.12),
          child: const Icon(Icons.savings_outlined, color: AppColors.warning),
        ),
        title: const Text('Enable Budget Recommendation', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          budgetEnabled
              ? 'Budget suggestion is shown in statistics'
              : 'Budget suggestion is hidden from statistics',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(value.isNotEmpty ? value : '-', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    );
  }

  InputDecoration _input(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }
}
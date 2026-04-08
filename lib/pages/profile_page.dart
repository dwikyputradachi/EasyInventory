import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _displayName = '';
  String _displayEmail = '';
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')), backgroundColor: color),
    );
  }

  void _onChangePhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Photo', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _sheetOption(Icons.camera_alt_outlined, 'Take a Photo', AppColors.textPrimary),
            const SizedBox(height: 12),
            _sheetOption(Icons.photo_library_outlined, 'Choose from Gallery', AppColors.textPrimary),
            const SizedBox(height: 12),
            _sheetOption(Icons.delete_outline, 'Remove Photo', AppColors.danger),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption(IconData icon, String label, Color color) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: color)),
        ]),
      );

  void _onSetPassword() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();
    bool oldVis = false, newVis = false, confirmVis = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Change Password', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _passField(oldPass, 'Current Password', oldVis, () => setDialog(() => oldVis = !oldVis)),
              const SizedBox(height: 12),
              _passField(newPass, 'New Password', newVis, () => setDialog(() => newVis = !newVis)),
              const SizedBox(height: 12),
              _passField(confirmPass, 'Confirm New Password', confirmVis, () => setDialog(() => confirmVis = !confirmVis)),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('• Min. 8 characters\n• Use letters and numbers',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary, height: 1.6)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPass.text != confirmPass.text) {
                  _showSnack('New passwords do not match.', AppColors.danger);
                  return;
                }
                if (newPass.text.length < 8) {
                  _showSnack('Password must be at least 8 characters.', AppColors.warning);
                  return;
                }
                Navigator.pop(context);
                _showSnack('Password changed successfully!', AppColors.primary);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.surface)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passField(TextEditingController c, String label, bool visible, VoidCallback onToggle) => TextField(
        controller: c,
        obscureText: !visible,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AppColors.textSecondary),
            onPressed: onToggle,
          ),
        ),
      );

  Widget _infoRow(IconData icon, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textPrimary)),
        ]),
      );

  Widget _buildField(String label, TextEditingController controller, String hint, IconData icon, {TextInputType keyboard = TextInputType.text}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              keyboardType: keyboard,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Photo + Info ──
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _onChangePhoto,
                  child: Stack(children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Icon(Icons.person, size: 48, color: AppColors.textSecondary),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 14, color: AppColors.surface),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                // Tampil nama & email kalau sudah ada, kalau belum tampil placeholder
                Text(
                  _displayName.isNotEmpty ? _displayName : 'Your Name',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _displayName.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _displayEmail.isNotEmpty ? _displayEmail : 'your@email.com',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: _displayEmail.isNotEmpty ? AppColors.textSecondary : AppColors.textSecondary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Form / Info Section ──
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PERSONAL INFO', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.8)),
                    GestureDetector(
                      onTap: () {
                        if (_isEditing) {
                          // saat ini mode edit, tombol jadi cancel
                          setState(() {
                            _isEditing = false;
                            _nameController.text = _displayName;
                            _emailController.text = _displayEmail;
                          });
                        } else {
                          // masuk mode edit, isi field dengan data saat ini
                          setState(() {
                            _isEditing = true;
                            _nameController.text = _displayName;
                            _emailController.text = _displayEmail;
                          });
                        }
                      },
                      child: Text(
                        _isEditing ? 'Cancel' : 'Edit',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, color: AppColors.background),

                if (_isEditing) ...[
                  // Mode edit: tampilkan form field
                  _buildField('Name', _nameController, 'Enter your full name', Icons.person_outline),
                  _buildField('Email', _emailController, 'Enter your email address', Icons.email_outlined, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _displayName = _nameController.text.trim();
                          _displayEmail = _emailController.text.trim();
                          _isEditing = false;
                        });
                        _showSnack('Profile saved!', AppColors.primary);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.surface)),
                    ),
                  ),
                ] else ...[
                  // Mode view: tampilkan info saja
                  _infoRow(Icons.person_outline, _displayName.isNotEmpty ? _displayName : '-'),
                  _infoRow(Icons.email_outlined, _displayEmail.isNotEmpty ? _displayEmail : '-'),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Password Management ──
          Container(
            color: AppColors.surface,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PASSWORD MANAGEMENT', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.8)),
                const Divider(height: 16, color: AppColors.background),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _onSetPassword,
                    icon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textPrimary),
                    label: const Text('Set Password', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textSecondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
}
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../data/app_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _name = '', _email = '';
  bool _isEditing = false;

  bool get _budgetEnabled => AppData().budgetRecommendationEnabled;

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')), backgroundColor: color));

  void _onChangePhoto() => showModalBottomSheet(
    context: context, backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Padding(padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Change Photo', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        _sheetItem(Icons.camera_alt_outlined, 'Take a Photo', AppColors.textPrimary),
        const SizedBox(height: 12),
        _sheetItem(Icons.photo_library_outlined, 'Choose from Gallery', AppColors.textPrimary),
        const SizedBox(height: 12),
        _sheetItem(Icons.delete_outline, 'Remove Photo', AppColors.danger),
        const SizedBox(height: 8),
      ]),
    ),
  );

  void _onChangePassword() {
    final oldC = TextEditingController(), newC = TextEditingController(), confC = TextEditingController();
    bool v1 = false, v2 = false, v3 = false;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Change Password', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _passField(oldC, 'Current Password', v1, () => set(() => v1 = !v1)),
        const SizedBox(height: 12),
        _passField(newC, 'New Password', v2, () => set(() => v2 = !v2)),
        const SizedBox(height: 12),
        _passField(confC, 'Confirm New Password', v3, () => set(() => v3 = !v3)),
        const SizedBox(height: 8),
        const Align(alignment: Alignment.centerLeft,
          child: Text('• Min. 8 characters\n• Use letters and numbers',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary, height: 1.6))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary))),
        ElevatedButton(
          onPressed: () {
            if (newC.text != confC.text) { _snack('Passwords do not match.', AppColors.danger); return; }
            if (newC.text.length < 8) { _snack('Min. 8 characters.', AppColors.warning); return; }
            Navigator.pop(ctx);
            _snack('Password changed!', AppColors.primary);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Save', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.surface)),
        ),
      ],
    )));
  }

  Widget _sheetItem(IconData icon, String label, Color color) => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 12), Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: color))]),
  );

  Widget _passField(TextEditingController c, String label, bool vis, VoidCallback toggle) => TextField(
    controller: c, obscureText: !vis,
    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label, labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
      filled: true, fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      suffixIcon: IconButton(icon: Icon(vis ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AppColors.textSecondary), onPressed: toggle),
    ),
  );

  Widget _infoRow(IconData icon, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [Icon(icon, size: 18, color: AppColors.primary), const SizedBox(width: 10),
      Text(value.isNotEmpty ? value : '-', style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textPrimary))]),
  );

  Widget _field(String label, TextEditingController c, String hint, IconData icon, {TextInputType kb = TextInputType.text}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      TextField(controller: c, keyboardType: kb,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
          filled: true, fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    ]),
  );

  Widget _section(String title, Widget child) => Container(
    color: AppColors.surface, width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.8)),
      const Divider(height: 16, color: AppColors.background),
      child, const SizedBox(height: 8),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Column(children: [

      // Photo + name
      Container(width: double.infinity, color: AppColors.surface, padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(children: [
          GestureDetector(onTap: _onChangePhoto,
            child: Stack(children: [
              Container(width: 90, height: 90,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.background, border: Border.all(color: AppColors.primary, width: 2)),
                child: const Icon(Icons.person, size: 48, color: AppColors.textSecondary)),
              Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, size: 14, color: AppColors.surface))),
            ]),
          ),
          const SizedBox(height: 10),
          Text(_name.isNotEmpty ? _name : 'Your Name',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600,
                color: _name.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(_email.isNotEmpty ? _email : 'your@email.com',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
        ]),
      ),

      const SizedBox(height: 8),

      // Personal Info
      Container(color: AppColors.surface, padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('PERSONAL INFO', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.8)),
            GestureDetector(
              onTap: () => setState(() { _isEditing = !_isEditing; _nameCtrl.text = _name; _emailCtrl.text = _email; }),
              child: Text(_isEditing ? 'Cancel' : 'Edit', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
            ),
          ]),
          const Divider(height: 16, color: AppColors.background),
          if (_isEditing) ...[
            _field('Name', _nameCtrl, 'Enter your full name', Icons.person_outline),
            _field('Email', _emailCtrl, 'Enter your email', Icons.email_outlined, kb: TextInputType.emailAddress),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() { _name = _nameCtrl.text.trim(); _email = _emailCtrl.text.trim(); _isEditing = false; _snack('Profile saved!', AppColors.primary); }),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Save Changes', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.surface)),
              )),
          ] else ...[
            _infoRow(Icons.person_outline, _name),
            _infoRow(Icons.email_outlined, _email),
          ],
          const SizedBox(height: 8),
        ]),
      ),

      const SizedBox(height: 8),

      // Password
      _section('PASSWORD MANAGEMENT', SizedBox(width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _onChangePassword,
          icon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textPrimary),
          label: const Text('Change Password', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      )),

      const SizedBox(height: 8),

      // App Settings — tulis & baca dari AppData
      _section('APP SETTINGS', Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Budget Recommendation', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textPrimary)),
          const Text('Show monthly budget based on past spending', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Switch(
          value: _budgetEnabled,
          onChanged: (v) => setState(() => AppData().budgetRecommendationEnabled = v),
          activeColor: AppColors.primary,
        ),
      ])),

      const SizedBox(height: 24),
    ]));
  }
}
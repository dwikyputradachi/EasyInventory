import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import '../data/app_data.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await ApiService.get('profile/get_profile.php');

    if (res['status'] == 'success') {
      final data = res['data'];

      AppData().setSession(
        token: AppData().token,
        userId: data['id_user'],
        name: data['name'],
        email: data['email'],
      );

      AppData().setProfilePhoto(data['profile_photo'] ?? '');
    }

    return res;
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    final res = await ApiService.post('profile/update_profile.php', {
      'name': name,
      'email': email,
    });

    if (res['status'] == 'success') {
      final data = res['data'];

      AppData().setSession(
        token: AppData().token,
        userId: data['id_user'],
        name: data['name'],
        email: data['email'],
      );
    }

    return res;
  }

  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await ApiService.post('profile/change_password.php', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  static Future<Map<String, dynamic>> uploadPhoto(String filePath) async {
    final uri = Uri.parse('${ApiService.baseUrl}/profile/upload_photo.php');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${AppData().token}';

    request.files.add(
      await http.MultipartFile.fromPath('photo', filePath),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    final res = jsonDecode(response.body);

    if (res['status'] == 'success') {
      final photo = res['data']['profile_photo'] ?? '';
      AppData().setProfilePhoto(photo);
    }

    return res;
  }
}
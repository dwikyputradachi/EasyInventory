import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_service.dart';
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
      await SessionService.saveSession();
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
      await SessionService.saveSession();
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
    try {
      final cleanBaseUrl = ApiService.baseUrl.endsWith('/') 
          ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1) 
          : ApiService.baseUrl;

      final uri = Uri.parse('$cleanBaseUrl/profile/update_photo.php');


      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${AppData().token}';

      request.files.add(
        await http.MultipartFile.fromPath('photo', filePath),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        return {
          'status': 'error',
          'message': 'Server Error (${response.statusCode}). Pastikan folder uploads sudah ada.'
        };
      }

      final res = jsonDecode(response.body);
      if (res['status'] == 'success' || res['success'] == true) {
        final photo = res['data']['profile_photo'] ?? '';
        AppData().setProfilePhoto(photo);
        await SessionService.saveSession();
        return {'status': 'success', 'data': res['data']};
      }

      return {
        'status': 'error',
        'message': res['message'] ?? 'Upload failed'
      };
      
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Exception: $e'
      };
    }
  }


  static Future<Map<String, dynamic>> verifyPassword(String password) async {
    return await ApiService.post('profile/verify_password.php', {
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> sendEmailChangeOtp(String newEmail) async {
    final res = await ApiService.post('auth/send_otp.php', {
      'email': newEmail,
      'purpose': 'change_email',
    });
    return _normalizeOtpResponse(res);
  }
  static Future<Map<String, dynamic>> verifyEmailChangeOtp({
    required String email,
    required String otp,
  }) async {
    final res = await ApiService.post('auth/verify_otp.php', {
      'email': email,
      'otp': otp,
      'purpose': 'change_email',
    });
    final normalized = _normalizeOtpResponse(res);

    if (normalized['status'] == 'success') {
      AppData().setSession(
        token: AppData().token,
        userId: AppData().userId,
        name: AppData().name,
        email: email,
      );
    }

    return normalized;
  }

  static Map<String, dynamic> _normalizeOtpResponse(Map<String, dynamic> res) {
    if (res.containsKey('status')) return res;
    return {
      'status': res['success'] == true ? 'success' : 'error',
      'message': res['message'],
    };
  }
}
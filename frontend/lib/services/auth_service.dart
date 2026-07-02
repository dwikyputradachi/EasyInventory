import 'api_service.dart';
import '../data/app_data.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await ApiService.post('auth/register.php', {
      'name': name,
      'email': email,
      'password': password,
      'role': 'user',
    });

    return res;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiService.post('auth/login.php', {
      'email': email,
      'password': password,
    });

    if (res['status'] == 'success') {
      final data = res['data'];

      AppData().setSession(
        token: data['token'] ?? '',
        userId: int.parse(data['id_user'].toString()),
        name: data['name'] ?? '',
        email: data['email'] ?? '',
      );
    }

    return res;
  }
static Future<Map<String, dynamic>> sendOTP({
  required String email,
  required String purpose,
}) async {
  return await ApiService.post(
    'auth/send_otp.php',
    {
      'email': email,
      'purpose': purpose,
    },
  );
}

static Future<Map<String, dynamic>> verifyOTP({
  required String email,
  required String otp,
  required String purpose,
}) async {
  return await ApiService.post(
    'auth/verify_otp.php',
    {
      'email': email,
      'otp': otp,
      'purpose': purpose,
    },
  );
}

static Future<Map<String, dynamic>> resetPassword({
  required String email,
  required String password,
}) async {
  return await ApiService.post(
    'auth/reset_password.php',
    {
      'email': email,
      'password': password,
    },
  );
}

  static void logout() {
    AppData().clearSession();
  }
}

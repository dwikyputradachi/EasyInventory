import 'api_service.dart';
import '../data/app_data.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return await ApiService.post('auth/register.php', {
      'name': name,
      'email': email,
      'password': password,
      'role': 'user',
    });
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiService.post('auth/login.php', {
      'email': email,
      'password': password,
    });

    if (res['success'] == true) {
      final data = res['data'];

      AppData().setSession(
        token: 'logged_in',
        userId: int.parse(data['id_user'].toString()),
        name: data['name'] ?? '',
        email: data['email'] ?? '',
      );
    }

    return res;
  }

  static void logout() {
    AppData().clearSession();
  }
}
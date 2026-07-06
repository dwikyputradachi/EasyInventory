import 'package:shared_preferences/shared_preferences.dart';
import '../data/app_data.dart';

class SessionService {
  static Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', AppData().token);
    await prefs.setInt('userId', AppData().userId);
    await prefs.setString('name', AppData().name);
    await prefs.setString('email', AppData().email);
    await prefs.setString('profilePhoto', AppData().profilePhoto);
  }

  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      return false;
    }

    AppData().token = token;
    AppData().userId = prefs.getInt('userId') ?? 0;
    AppData().name = prefs.getString('name') ?? '';
    AppData().email = prefs.getString('email') ?? '';
    AppData().profilePhoto =
        prefs.getString('profilePhoto') ?? '';

    return true;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
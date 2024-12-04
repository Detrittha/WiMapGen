import 'package:shared_preferences/shared_preferences.dart';

class Config {
  static Future<String> getHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('host') ?? '192.168.254.20:3000'; // ค่าเริ่มต้นถ้าไม่มีการสแกน
  }
}
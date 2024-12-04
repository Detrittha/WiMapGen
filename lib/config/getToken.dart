import 'package:shared_preferences/shared_preferences.dart';


  Future<String?> _getToken() async {
  // สมมติว่าคุณใช้ SharedPreferences เพื่อเก็บ token
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');
  return token;
}
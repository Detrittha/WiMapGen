import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:wimapgen/menu/wifi_info_screen.dart';
import 'package:wimapgen/menu/registerPage.dart';
import 'package:wimapgen/config/hostname.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slider_captcha/slider_captcha.dart';
import 'package:wimapgen/model/user_model.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:wimapgen/menu/IPAddressPortPage.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String _ipAddress = '';
  int _port = 0;

  @override
void initState() {
  super.initState();
  _loadConnectionDetails();
  
}

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    
    super.dispose();
  }

  Future<void> _loadConnectionDetails() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {
    _ipAddress = prefs.getString('ip_address') ?? '192.168.136.20';
    _port = prefs.getInt('port') ?? 3000;
  });
}


Future<void> _performLogin() async {
  print('IP Address $_ipAddress');

  if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
    _showErrorSnackBar(context, "Please enter email and password.");
    return;
  }
   
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );
  try {
    // final url = Uri.parse('http://$host/api/login');
     final url = Uri.parse('http://$_ipAddress:$_port/api/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      }),
    );

    Navigator.of(context).pop(); // Close loading dialog

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData['auth'] == true) {
        await _saveSession(responseData['token']);
        final user = User.fromJson(responseData['user']);
        await _saveUser(user);
        _getUser();
        _getSession();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WifiInfoScreen(isLoggedIn: true, user: user,),
          ),
        );
      } else {
        _showErrorSnackBar(context, "Login failed. Please check your credentials and try again.");
      }
    } else if (response.statusCode == 429) {
      _showErrorSnackBar(context, "Too many requests from this IP, please try again after a minute");
    } else {
      _showErrorSnackBar(context, "Login failed. Invalid email or password");
    }
  } catch (error) {
    if (error is SocketException) {
      _showErrorSnackBar(context, "Network error. Please check your internet connection.");
    } else if (error is TimeoutException) {
      _showErrorSnackBar(context, "Request timed out. Please try again.");
    } else {
      _showErrorSnackBar(context, "Error during login: $error");
      print("Error during login: $error");
    }
  }
}

Future<void> _saveUser(User user) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_data', json.encode(user.toJson()));
 
}

Future<User?> _getUser() async {
  final prefs = await SharedPreferences.getInstance();
  final userData = prefs.getString('user_data');
  if (userData != null) {
    checkStoredUserData();
    print('Raw stored data: $userData');
    final decodedData = json.decode(userData);
    print('Decoded data: $decodedData');
    final user = User.fromJson(decodedData);
    print('Parsed User Data:');
    print('User ID: ${user.userId} (${user.userId.runtimeType})');
    print('Role: ${user.role} (${user.role.runtimeType})');
    print('First Name: ${user.firstName}');
    return user;
  }
  print('No user data found');
  return null;
}
Future<void> checkStoredUserData() async {
  final prefs = await SharedPreferences.getInstance();
  final userData = prefs.getString('user_data');
  if (userData != null) {
    print('Raw stored data: $userData');
    final decodedData = json.decode(userData);
    print('Decoded data: $decodedData');
    print('User_id type: ${decodedData['User_id'].runtimeType}');
    print('User_id value: ${decodedData['User_id']}');
  } else {
    print('No user data found');
  }
}


  Future<void> _saveSession(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> _getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  

  Future<void> _removeSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  


  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  Widget _buildForgotText() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        'Forgot password?',
        style: TextStyle(
          fontSize: 13.0,
          fontStyle: FontStyle.normal,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 50.0,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showRecaptchaDialog(),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        child: const Text(
          "Login",
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }



  
  void _showRecaptchaDialog() {
  int randomNumber = Random().nextInt(22) + 1;
  
  bool isVerified = false;
  final imageSize = Size(300, 180);
  final puzzlePieceSize = 50.0;

  
  final random = Random();
  Offset targetPosition = Offset(
    random.nextDouble() * (imageSize.width - puzzlePieceSize),
    random.nextDouble() * (imageSize.height - puzzlePieceSize),
  );

  
  Offset puzzlePiecePosition = Offset(0, imageSize.height / 2);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Human Verification",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Drag the puzzle piece to complete the image",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 24),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/image_Recaptcha/$randomNumber.jpg',
                          fit: BoxFit.cover,
                          height: imageSize.height,
                          width: imageSize.width,
                        ),
                      ),
                      Positioned(
                        left: targetPosition.dx,
                        top: targetPosition.dy,
                        child: Container(
                          width: puzzlePieceSize,
                          height: puzzlePieceSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            border: Border.all(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        left: puzzlePiecePosition.dx,
                        top: puzzlePiecePosition.dy,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              Offset newPosition = puzzlePiecePosition + details.delta;
                              puzzlePiecePosition = Offset(
                                newPosition.dx.clamp(0, imageSize.width - puzzlePieceSize-50),
                                newPosition.dy.clamp(0, imageSize.height - puzzlePieceSize),
                              );
                            });
                          },
                          onPanEnd: (details) {
                            if ((puzzlePiecePosition - targetPosition).distance < 20) {
                              setState(() {
                                isVerified = true;
                                puzzlePiecePosition = targetPosition;
                              });
                              Future.delayed(Duration(milliseconds: 500), () {
                                Navigator.of(context).pop();
                                _performLogin();
                              });
                            }
                          },
                          child: Container(
                            width: puzzlePieceSize,
                            height: puzzlePieceSize,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.7),
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.drag_indicator, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  if (isVerified)
                    Text(
                      "Verification Successful!",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue[700]),
                        onPressed: () {
                          setState(() {
                            randomNumber = Random().nextInt(22) + 1;
                            isVerified = false;
                            targetPosition = Offset(
                              random.nextDouble() * (imageSize.width - puzzlePieceSize),
                              random.nextDouble() * (imageSize.height - puzzlePieceSize),
                            );
                            puzzlePiecePosition = Offset(0, imageSize.height / 2);
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red[400]),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Login Success!"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade200,
            Colors.blue.shade50,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.black),
              onPressed: () async {
                bool? result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => IPAddressPortPage()),
            );if (result != null && result) {
              // ผลลัพธ์ที่ส่งกลับมาเป็น true
              _loadConnectionDetails();
              print(_ipAddress);
              print(_port);
              print('Received true from IPAddressPortPage');
              // ดำเนินการเพิ่มเติมที่ต้องการ
            } else {
              // ผลลัพธ์ที่ส่งกลับมาเป็น false หรือ null
               _loadConnectionDetails();
              print(_ipAddress);
              print(_port);
              print('No true result received from IPAddressPortPage');
            }
              }
              // onPressed: () {
              //   Navigator.push(context, MaterialPageRoute(builder: (context)=> IPAddressPortPage()));
                
              // },
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/logo1.png',
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20.0),
                  Card(
                    elevation: 8.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            labelText: 'Email',
                            prefixIcon: Icons.person,
                          ),
                          const SizedBox(height: 20.0),
                          _buildTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            prefixIcon: Icons.lock,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          _buildLoginButton(),
                          const SizedBox(height: 20.0),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const WifiInfoScreen(isLoggedIn: false),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Text(
                                  'Use without logging in',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Copyright © 2023 wimapgen',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}



}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'dart:async';
import 'package:wimapgen/menu/loginPage.dart';
import 'package:wimapgen/config/hostname.dart';
import 'package:wimapgen/menu/wifi_info_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
class GeneratePage extends StatefulWidget {
  const GeneratePage({Key? key}) : super(key: key);

  @override
  _GeneratePageState createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> {
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _fnameError = '';
  String _lnameError = '';
  String _emailError = '';
  String _passwordError = '';
  String _confirmPasswordError = '';
  String _errorMessage = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

   String _ipAddress = '';
  int _port = 0;

  void initState(){
    super.initState();
    _loadConnectionDetails();
  }
 
    Future<void> _loadConnectionDetails() async {
    
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {

    _ipAddress = prefs.getString('ip_address') ?? '192.168.136.20';
    _port = prefs.getInt('port') ?? 3000;
    
    
  });}
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    onPopInvoked: (bool didPop) async {
      if (didPop) return;
      // You can add custom logic here if needed
      // For example, show a dialog to confirm exit
    },
    child: Scaffold(
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/images/logo1.png'),
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
                          controller: _fnameController,
                          labelText: 'Firstname',
                          prefixIcon: Icons.person,
                          errorText:
                              _fnameError.isNotEmpty ? _fnameError : null,
                        ),
                        const SizedBox(height: 20.0),
                        _buildTextField(
                          controller: _lnameController,
                          labelText: 'Lastname',
                          prefixIcon: Icons.person,
                          errorText:
                              _lnameError.isNotEmpty ? _lnameError : null,
                        ),
                        const SizedBox(height: 20.0),
                        _buildTextField(
                          controller: _emailController,
                          labelText: 'Email',
                          prefixIcon: Icons.email,
                          errorText:
                              _emailError.isNotEmpty ? _emailError : null,
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
                          errorText:
                              _passwordError.isNotEmpty ? _passwordError : null,
                        ),
                        const SizedBox(height: 20.0),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          prefixIcon: Icons.lock,
                          obscureText: !_isConfirmPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          errorText: _confirmPasswordError.isNotEmpty
                              ? _confirmPasswordError
                              : null,
                        ),
                        const SizedBox(height: 20.0),
                        if (_errorMessage.isNotEmpty)
                          Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red),
                          ),
                        const SizedBox(height: 20.0),
                        _buildGenerateButton(),
                        const SizedBox(height: 10.0),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WifiInfoScreen(isLoggedIn: true)),
                      );
                          },
                          child: const Text('Go Back',
                          style:  TextStyle(
                            color: Colors.grey,
                          )
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
      ),
    ),
  );
}

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
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
        errorText: errorText,
        errorStyle: TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      height: 50.0,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _validateAndGenerate,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        child: const Text(
          'Generate',
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
String? _validatePassword(String value) {
  Map<String, bool> requirements = {
    'Length (at least 8 characters)': value.length >= 8,
    'Uppercase letter': value.contains(RegExp(r'[A-Z]')),
    'Lowercase letter': value.contains(RegExp(r'[a-z]')),
    'Number': value.contains(RegExp(r'[0-9]')),
    'Special character': value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
  };

  if (value.isEmpty) {
    return 'Password is required';
  }

  List<String> failedRequirements = requirements.entries
      .where((entry) => !entry.value)
      .map((entry) => entry.key)
      .toList();

  if (failedRequirements.isNotEmpty) {
    String passedRequirements = requirements.entries
        .where((entry) => entry.value)
        .map((entry) => '✓ ${entry.key}')
        .join('\n');
    
    String failedRequirementsText = failedRequirements
        .map((req) => '✗ $req')
        .join('\n');

    return 'Password requirements:\n$passedRequirements\n$failedRequirementsText';
  }

  return null;
}


  void _validateAndGenerate() async {
     setState(() {
    _fnameError = _fnameController.text.isEmpty ? 'Firstname is required' : '';
    _lnameError = _lnameController.text.isEmpty ? 'Lastname is required' : '';
    _emailError = _validateEmail(_emailController.text) ?? '';
    _passwordError = _validatePassword(_passwordController.text) ?? '';
    _confirmPasswordError = _confirmPasswordController.text.isEmpty ? 'Confirm Password is required' : '';

    if (_passwordController.text != _confirmPasswordController.text) {
      _confirmPasswordError = 'Passwords do not match';
    }
  });

    if (_fnameError.isNotEmpty ||
        _lnameError.isNotEmpty ||
        _emailError.isNotEmpty ||
        _passwordError.isNotEmpty ||
        _confirmPasswordError.isNotEmpty) {
      setState(() {
        _errorMessage = 'Please correct the errors and try again.';
      });
      return;
    }

    // Clear error message if all validations pass
    setState(() {
      _errorMessage = '';
    });

    // Prepare data for API request
    final String firstname = _fnameController.text;
    final String lastname = _lnameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;

    final url = Uri.parse('http://${_ipAddress}:${_port}/api/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'f_name': firstname,
          'l_name': lastname,
          'role': 1,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        showLoginSuccessDialog(context);
        print('Registration successful');
      } else {
        print('Registration failed: ${response.body}');
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      print('Error during registration: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return 'Email is required';
    } else if (!EmailValidator.validate(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void showLoginSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: contentBox(context),
        );
      },
    );
  }

  Widget contentBox(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 65, 20, 20),
          margin: const EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Account successfully created!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Do you want to generate more or return?",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton(
                    context,
                    "Generate",
                    Colors.blue,
                    Colors.white,
                    () {
                      Navigator.pop(context); // ปิด Dialog
                      // ดำเนินการเพิ่มเติมที่นี่ เช่น นำทางไปยังหน้าถัดไป
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GeneratePage()),
                      );
                    },
                  ),
                  _buildButton(
                    context,
                    "Return",
                    Colors.white,
                    Colors.blue,
                    () => _navigateToWifiScreen(context, false),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: CircleAvatar(
            backgroundColor: Colors.green,
            radius: 45,
            child: const Icon(
              Icons.check,
              size: 50,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }

  void _navigateToWifiScreen(BuildContext context, bool generateMore) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WifiInfoScreen(isLoggedIn: true),
      ),
    );
  }
}

class CountDownWidget extends StatefulWidget {
  final Function onCountDownFinish;

  const CountDownWidget({Key? key, required this.onCountDownFinish})
      : super(key: key);

  @override
  _CountDownWidgetState createState() => _CountDownWidgetState();
}

class _CountDownWidgetState extends State<CountDownWidget> {
  int countDown = 5;

  @override
  void initState() {
    super.initState();
    startCountDown();
  }

  void startCountDown() {
    const oneSec = Duration(seconds: 1);
    Timer.periodic(oneSec, (Timer timer) {
      if (countDown == 0) {
        setState(() {
          timer.cancel();
          widget.onCountDownFinish(); // Call callback function
        });
      } else {
        setState(() {
          countDown--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$countDown',
      style: TextStyle(
          fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'dart:async';
import 'package:wimapgen/menu/loginPage.dart';
import 'package:wimapgen/config/hostname.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}
class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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

@override
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
                          errorText: _fnameError.isNotEmpty ? _fnameError : null,
                        ),
                        const SizedBox(height: 20.0),
                        _buildTextField(
                          controller: _lnameController,
                          labelText: 'Lastname',
                          prefixIcon: Icons.person,
                          errorText: _lnameError.isNotEmpty ? _lnameError : null,
                        ),
                        const SizedBox(height: 20.0),
                        _buildTextField(
                          controller: _emailController,
                          labelText: 'Email',
                          prefixIcon: Icons.email,
                          errorText: _emailError.isNotEmpty ? _emailError : null,
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
                          errorText: _passwordError.isNotEmpty ? _passwordError : null,
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
                          errorText: _confirmPasswordError.isNotEmpty ? _confirmPasswordError : null,
                        ),
                        const SizedBox(height: 20.0),
                        if (_errorMessage.isNotEmpty)
                          Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red),
                          ),
                        const SizedBox(height: 20.0),
                        _buildRegisterButton(),
                        const SizedBox(height: 10.0),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Already have an account? Login',
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

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 50.0,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showRecaptchaDialog,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        child: const Text(
          'Register',
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
                                _validateAndRegister();
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


  void _validateAndRegister() async {
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
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 20, top: 45, right: 20, bottom: 20),
          margin: EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              SizedBox(height: 25),
              Text(
                'Successful',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              Text(
                'Returning to the login page in:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              CountDownWidget(onCountDownFinish: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class CountDownWidget extends StatefulWidget {
  final Function onCountDownFinish;

  const CountDownWidget({Key? key, required this.onCountDownFinish}) : super(key: key);

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
      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green),
    );
  }
}
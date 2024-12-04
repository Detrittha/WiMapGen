import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert'; // For base64Encode and base64Decode
import 'dart:typed_data'; // For Uint8List
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wimapgen/config/hostname.dart';
import 'package:wimapgen/model/user_model.dart';

class ProfilePage extends StatefulWidget {
  final String? firstName;
  final String? lastName;
  final String? description;
  final String? image;
  final String? userId;

  const ProfilePage({
    Key? key,
    this.firstName,
    this.lastName,
    this.description,
    this.image,
    this.userId,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _descriptionController;
  final ImagePicker _imagePicker = ImagePicker();
 String _ipAddress = '';
  int _port = 0;

  // XFile? _profileImage;
  User? _user;
  String? imagePath = '';
  @override
  void initState() {
    super.initState();
    _loadConnectionDetails();
     _checkDataUser();
     _checkSession();
     _setstate();
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _descriptionController = TextEditingController(text: widget.description);
  }

   Future<void> _loadConnectionDetails() async {
    
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {

    _ipAddress = prefs.getString('ip_address') ?? '192.168.136.20';
    _port = prefs.getInt('port') ?? 3000;
    
    
  });}

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  

  
  void _setstate()  {
    
  if( widget.image != null && widget.image!.isNotEmpty){
      imagePath = widget.image;
      // print(imagePath);
  }else{
    imagePath = '$defaultImg';
    // print(imagePath);
  }
  
  }


Future<void> _pickImage() async {
  final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    try {
      String imagebase64 = await convertImageToBase64(pickedFile.path);
      print(imagebase64);
      setState(() {
        imagePath= imagebase64; // ใช้ widget.image แทน imagePath
      });
    } catch (e) {
      print('Error converting image to base64: $e');
      // แสดง SnackBar หรือ AlertDialog เพื่อแจ้งผู้ใช้ว่ามีข้อผิดพลาด
    }
  }
}

  Future<void> _pickImageFromCamera() async {
  final ImagePicker _picker = ImagePicker();
  final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);

  if (pickedFile != null) {
    // อ่านไฟล์ภาพที่เลือกเป็น byte
    final bytes = await pickedFile.readAsBytes();
    // เข้ารหัสเป็น Base64 string
    final base64Image = base64Encode(bytes);

    setState(() {
      // อัปเดตสถานะของ imageData
      imagePath = base64Image;
    });
  }
}

  
  Future<String?> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token == null) {
      // print('asasd');
    } else {
      // print('asasd');
    }
    return token;
  }

   Future<void> _checkDataUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    // print('user id at line 119  : ${userId}');
    if (userData != null) {
      setState(() {
        _user = User.fromJson(json.decode(userData));
      });
    }
  }
  Future<String> convertImageToBase64(String filePath) async {
  try {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  } catch (e) {
    print('Error converting image to Base64: $e');
    return '';
  }
}

  
  Future<void> _updateUserImage(int? userId,String? image2base64) async {
    String? token = await _checkSession();
    if (token == null) {
      print('Error: No valid session token');
      return;
    }
    print(_user?.userId);
    try {
      final response = await http.put(
        Uri.parse('http://${_ipAddress}:${_port}/api/update-image/${_user?.userId}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'image': image2base64,
        }),
      );

      if (response.statusCode == 200) {
        print(' updated successfully');
    //  ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Profile updated successfully'),
    //     backgroundColor: Colors.green,
    //   ),
    // );
      } else {
        print('Failed to update: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error updating : $e');
    }
  }

  Future<void> _updateUserFName(int? userId, String newFirstName) async {
  String? token = await _checkSession();
  if (token == null) {
    print('Error: No valid session token');
    return;
  }
  
  if (userId == null || newFirstName == null) {
    print('Error: User ID or new first name is null');
    return;
  }

  try {
    final response = await http.put(
      Uri.parse('http://${_ipAddress}:${_port}/api/user/updateFname/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'f_name': newFirstName,
      }),
    );

    if (response.statusCode == 200) {
      print('First name updated successfully');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('First name updated successfully'),
      //     backgroundColor: Colors.green,
      //   ),
      // );
    } else {
      print('Failed to update first name: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    print('Error updating first name: $e');
  }
}


  Future<void> _updateUserLName(int? userId, String newLastName) async {
  String? token = await _checkSession();
  if (token == null) {
    print('Error: No valid session token');
    return;
  }
  
  if (userId == null || newLastName == null) {
    print('Error: User ID or new first name is null');
    return;
  }

  try {
    final response = await http.put(
      Uri.parse('http://${_ipAddress}:${_port}/api/user/updateLname/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'l_name': newLastName,
      }),
    );

    if (response.statusCode == 200) {
      print('Last name updated successfully');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('First name updated successfully'),
      //     backgroundColor: Colors.green,
      //   ),
      // );
    } else {
      print('Failed to update last name: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    print('Error updating last name: $e');
  }
}

Future<void> _updateUserDescription(int? userId, String? newDescription) async {
  String? token = await _checkSession();
  if (token == null) {
    print('Error: No valid session token');
    return;
  }

  if (userId == null || newDescription == null) {
    print('Error: User ID or new description is null');
    return;
  }

  try {
    final response = await http.put(
      Uri.parse('http://${_ipAddress}:${_port}/api/user/updateDescript/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'description': newDescription,
      }),
    );

    if (response.statusCode == 200) {
      print('Description updated successfully');
     
    } else {
      print('Failed to update description: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    print('Error updating description: $e');
  }
}

  void _viewImage() {
  if (widget.image != null && widget.image!.isNotEmpty) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(base64Decode(widget.image!)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}
Widget build(BuildContext context) {
  return PopScope(
    canPop: false, // ป้องกันการปิดหน้าจอด้วยวิธีปกติ
    onPopInvoked: (didPop) async {
      if (didPop) return;
      // ส่งค่า true กลับไปเมื่อหน้าจอถูกปิด
      Navigator.pop(context, true);
    },
    child: Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, true), // ส่งค่า true กลับไปเมื่อทำการอัพเดตสำเร็จ
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildInfoSection(context),
          ],
        ),
      ),
    ),
  );
}
Widget _buildHeader() {
  return Container(
    height: 220,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: -40,
          left: 0,
          right: 0,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/logo1.png'), // Correct way to use AssetImage
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: GestureDetector(
            onTap: _showImageOptions, // Add gesture detector
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: widget.image != null && widget.image!.isNotEmpty
                    ? MemoryImage(base64Decode(imagePath!))
                    : null,
                child: widget.image == null || widget.image!.isEmpty
                    ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                    : null,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 120,
          child: FloatingActionButton(
            onPressed: _showImageOptions,
            child: Icon(Icons.camera_alt),
            mini: true,
            backgroundColor: const Color.fromARGB(255, 199, 199, 199),
            foregroundColor: Colors.black,
          ),
        ),
      ],
    ),
  );
}
void _showImageOptions() {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Camera'),
            onTap: () {
              Navigator.of(context).pop();
              _pickImageFromCamera();
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Choose a profile picture'),
            onTap: () {
              Navigator.of(context).pop();
              _pickImage();
            },
          ),
           ListTile(
            leading: Icon(Icons.photo),
            title: Text('Viwe profile'),
            onTap: () {
              Navigator.of(context).pop();
              _viewImage();
            },
          ),
          ListTile(
            leading: Icon(Icons.remove_circle),
            title: Text('Delete'),
            onTap: () {
              Navigator.of(context).pop();
              _removeImage();
            },
          ),
        ],
      );
    },
  );
}
void _removeImage() {
  setState(() {
    imagePath = '$defaultImg'; // รีเซ็ตค่า imageData เป็น null
  });
}



  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField('First Name', _firstNameController),
          SizedBox(height: 16),
          _buildTextField('Last Name', _lastNameController),
          SizedBox(height: 16),
          _buildTextField('About Me', _descriptionController, maxLines: 4),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveProfile,
            child: Text(
              'Save Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold, // Added bold text for emphasis
                color: Colors
                    .white, // Ensures text is readable on darker backgrounds
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.blue[700], // Darker blue for better visibility
              padding: EdgeInsets.symmetric(
                  vertical: 15, horizontal: 30), // Added horizontal padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5, // Adds a subtle shadow for a raised effect
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      maxLines: maxLines,
    );
  }

  void _saveProfile() {
    _updateUserImage(_user?.userId, imagePath);
    _updateUserFName(_user?.userId, _firstNameController.text);
    _updateUserLName(_user?.userId, _lastNameController.text);
     _updateUserDescription(_user?.userId, _descriptionController.text);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
  }
}

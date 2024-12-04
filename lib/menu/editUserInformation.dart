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

class EditInformationUser extends StatefulWidget {
 final String? firstName;
  final String? lastName;
  final String? description;
  final String? image;
  final String? email;
  final int? userId;

  const EditInformationUser({
    Key? key,
    this.firstName,
    this.lastName,
    this.description,
    this.image,
    this.email,
    this.userId,
  }) : super(key: key);


  @override
  _EditInformationUserState createState() => _EditInformationUserState();
}

class _EditInformationUserState extends State<EditInformationUser> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Dummy data for email and image
   String? _email ='';
   String? _imagebase64 = '';
   Uint8List? _imageBytes;
    String _ipAddress = '';
  int _port = 0;

  @override
  void initState() {
    super.initState();
    _loadConnectionDetails();
     _checkSession();
    print(widget.email.toString());
    _email = widget.email;
     if (widget.image != null) {
      _imageBytes = base64Decode(widget.image!);
    }
    // Initialize controllers with current user data
    _firstNameController.text = widget.firstName.toString(); // Replace with actual data
    _lastNameController.text = widget.lastName.toString();  // Replace with actual data
    _descriptionController.text = widget.description.toString(); // Replace with actual data
  }

  
    Future<void> _loadConnectionDetails() async {
    
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {

    _ipAddress = prefs.getString('ip_address') ?? '192.168.136.20';
    _port = prefs.getInt('port') ?? 3000;
    
    
  });}
@override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); 
        // ส่งค่ากลับเป็น true เมื่อกดปุ่ม back
        return false; // Return false เพื่อป้องกันการปิดหน้าต่างปกติ
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit User Information'),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                _saveProfile();
              },
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageBytes != null
                      ? MemoryImage(_imageBytes!)
                      : AssetImage('assets/images/person1.png') as ImageProvider,
                  child: _imageBytes == null
                      ? Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _email,
                enabled: false,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'First Name',
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Last Name',
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Description',
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  void _saveProfile() {
    
    _updateUserFName(widget.userId, _firstNameController.text);
    _updateUserLName(widget.userId, _lastNameController.text);
     _updateUserDescription(widget.userId, _descriptionController.text);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
  }



}
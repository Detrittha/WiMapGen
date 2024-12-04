import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IPAddressPortPage extends StatefulWidget {
  @override
  _IPAddressPortPageState createState() => _IPAddressPortPageState();
}

class _IPAddressPortPageState extends State<IPAddressPortPage> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.blue.shade100],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Configure Connection',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildIPAddressField(),
                          SizedBox(height: 20),
                          _buildPortField(),
                          SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _submitForm,
                            child: Text('Connect'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              textStyle: TextStyle(fontSize: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIPAddressField() {
    return TextFormField(
      controller: _ipController,
      decoration: InputDecoration(
        labelText: 'IP Address',
        prefixIcon: Icon(Icons.computer),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an IP address';
        }
        // Add more sophisticated IP validation if needed
        return null;
      },
    );
  }

  Widget _buildPortField() {
    return TextFormField(
      controller: _portController,
      decoration: InputDecoration(
        labelText: 'Port',
        prefixIcon: Icon(Icons.podcasts),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a port number';
        }
        int? port = int.tryParse(value);
        if (port == null || port < 0 || port > 65535) {
          return 'Please enter a valid port number (0-65535)';
        }
        return null;
      },
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String ipAddress = _ipController.text;
      int port = int.parse(_portController.text);
    
      // บันทึก IP address และ port ลงในเครื่อง
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('ip_address', ipAddress);
      await prefs.setInt('port', port);
    
      print('Saved connection details: $ipAddress:$port');
    
      // แสดงข้อความยืนยันการบันทึก
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection details saved')),
      );
    
      // ปิดหน้านี้และกลับไปยังหน้าก่อนหน้า พร้อมส่งค่า true กลับไป
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}

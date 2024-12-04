import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:wimapgen/menu/custompaint.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wimapgen/menu/wifi_info_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wimapgen/model/user_model.dart';
import 'dart:convert';
import 'package:wimapgen/model/map_model.dart';
import 'package:http/http.dart' as http;
import 'package:wimapgen/config/hostname.dart';
import 'dart:math'; // Import สำหรับ max และ min
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';

class CreateHeatmap extends StatefulWidget {
  final WiFiAccessPoint accessPoint;
  final Function updateSignalStrength;
  final String imagePath;
  final String location;
  final String name;
  final int? mapID;


  const CreateHeatmap({
    Key? key,
    required this.accessPoint,
    required this.updateSignalStrength,
    required this.imagePath,
    required this.location,
    required this.name,
     this.mapID,
 
  }) : super(key: key);

  @override
  _CreateHeatmapState createState() => _CreateHeatmapState();
}

class _CreateHeatmapState extends State<CreateHeatmap> {
  late double currentSignalStrength;
  late Timer timer;
  Offset pinPosition = Offset.zero;
  List<CustomCircle> circles = [];
  User? _user;
  bool isLoggedIn = false;
  List<double> ChkDbm = [];
  bool isVisiblePin = true;
  bool  _isLoading = false;
  bool isLoading = false;
  String displaySignalStrength = ''; 
  int MapID=0;
  String _ipAddress = '';
  int _port = 0;


  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    setState(() {
      MapID++;
  });
    // _loadConnectionDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        pinPosition = getCenterPosition(context);
      });
    });
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      updateSignalStrength();
      getMaxMinValues();
      // print(widget.name);
    });
    currentSignalStrength = widget.accessPoint.level.toDouble();
  }

  //   Future<void> _loadConnectionDetails() async {
    
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // setState(() {

  //   _ipAddress = prefs.getString('ip_address') ?? '192.168.136.20';
  //   _port = prefs.getInt('port') ?? 3000;
    
    
  // });}

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _checkDataUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    // print('user id at line 119  : ${userId}');
    if (userData != null) {
      setState(() {
        _user = User.fromJson(json.decode(userData));
        isLoggedIn = true;
      });
    }
  }
Map<String, dynamic> getMaxMinValues() {
  double maxSignalStrength = double.negativeInfinity;
  double minSignalStrength = double.infinity;

  if (ChkDbm.isNotEmpty) {
    maxSignalStrength = ChkDbm.reduce((a, b) => a > b ? a : b);
    minSignalStrength = ChkDbm.reduce((a, b) => a < b ? a : b);
  } else {
    // Handle the case where ChkDbm is empty
    maxSignalStrength = 0.0;
    minSignalStrength = 0.0;
  }

  return {
    'Max_dBm': maxSignalStrength.toString(),
    'Min_dBm': minSignalStrength.toString(),
  };
}
  Offset getCenterPosition(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 3;
    return Offset(centerX, centerY);
  }

  @override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    onPopInvoked: (bool didPop) async {
      if (didPop) return;
      final bool shouldPop = await _onWillPop(context);
      if (shouldPop) {
        Navigator.of(context).pop();
      }
    },
    child: Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/logo1.png',
              height: MediaQuery.of(context).size.height * 0.25,
              width: MediaQuery.of(context).size.width * 0.25,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Screenshot(
            controller: screenshotController,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildMapDetailWithCircles(context),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.26,
                  child: Container(
                    color: Colors.white,
                    child: _buildTopContainer(
                      widget.accessPoint,
                      widget.location,
                      widget.name,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.26,
                  child: _buildBottomContainer(),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Stack(
                children: [
                  Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}



  
Future<bool> _onWillPop(BuildContext context) async {
  if (widget.mapID == -0) {
    // แสดง Popup อื่นถ้า mapId เท่ากับ -0
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Information'),
          content: Text('You need to register before saving. Leaving now will delete the Wi-Fi survey heatmap. Proceed?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // ป้องกันการย้อนกลับ
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // อนุญาตให้ย้อนกลับ
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    ) ?? false;
  } else {
    if (_isLoading) return false; // ถ้ามีการโหลดอยู่ ให้ไม่ทำอะไร

    // แสดงกล่องข้อความยืนยัน
    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Save Changes?'),
          content: Text('Do you want to save the changes before leaving?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // ป้องกันการย้อนกลับ
                // _deleteProject(widget.mapID);
              },
              child: Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // อนุญาตให้ย้อนกลับ
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    // ถ้าผู้ใช้เลือกบันทึก
    if (shouldSave == true) {
      setState(() {
        _isLoading = true; // เริ่มการโหลด
      });

      try {
        await _captureAndSaveToDatabase(); // บันทึกข้อมูล
      } catch (e) {
        // print('Error saving data: $e');
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Error saving data: $e')),
        // );
      } finally {
        setState(() {
          _isLoading = false; // สิ้นสุดการโหลด
        });
      }
    }

    // นำทางกลับไปที่ WifiInfoScreen หากผู้ใช้ไม่ยกเลิก
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => WifiInfoScreen(isLoggedIn: isLoggedIn),
      ),
      (Route<dynamic> route) => false,
    );
    return false; // ป้องกันการย้อนกลับตามปกติ
  }
}


Future<void> _captureAndSaveToDatabase() async {
  // เริ่มการโหลด
  setState(() {
    _isLoading = true;
    isVisiblePin = false; // แสดงสถานะการโหลด
  });

  try {
    // ใช้ screenshotController เพื่อจับภาพ
    final Uint8List? imageBytes = await screenshotController.capture();
    if (imageBytes != null) {
      // แปลง Uint8List เป็น Base64 string
      String base64Image = base64Encode(imageBytes);
      // print(base64Image);
      
      // บันทึกข้อมูลลงฐานข้อมูล
      await _saveVersion(context);
      
      // แสดงข้อความแจ้งเตือนสำเร็จ
     
    } else {
      // แสดงข้อความแจ้งเตือนข้อผิดพลาดเมื่อจับภาพล้มเหลว
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture widget')),
      );
    }
  } catch (e) {
    // แสดงข้อความแจ้งเตือนข้อผิดพลาดเมื่อเกิดข้อผิดพลาด
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    // สิ้นสุดสถานะการโหลด
    setState(() {
      _isLoading = false;
    });
  }
}
  

  Future<String> convertImageToBase64(String? imagePath) async {
    if (imagePath == null) {
      throw Exception('File path is null');
    }

    List<int> imageBytes;

    if (imagePath.startsWith('assets/')) {
      // Image from assets
      try {
        ByteData data = await rootBundle.load(imagePath);
        imageBytes = data.buffer.asUint8List();
      } catch (e) {
        throw Exception('Failed to load asset: $e');
      }
    } else {
      // Image from file system
      File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('File not found: $imagePath');
      }
      try {
        imageBytes = await imageFile.readAsBytes();
      } catch (e) {
        throw Exception('Failed to read file: $e');
      }
    }

    String base64Image = base64Encode(imageBytes);
   
    // print(defaultIMG);
    return base64Image;
  }

    static int generateUniqueMapID() {

    int timestamp = DateTime.now().millisecondsSinceEpoch;

    int randomValue = Random().nextInt(100000); // Random number between 0 and 99999

 
    return timestamp + randomValue;
  }

    static int generateUniqueverID() {

    int timestamp = DateTime.now().millisecond;

    int randomValue = Random().nextInt(100000); // Random number between 0 and 99999

 
    return timestamp + randomValue;
  }

  Future<void> _saveVersion(BuildContext context) async {

  try {
    // Capture the screen
    final Uint8List? imageBytes = await screenshotController.capture();
    
    if (imageBytes != null) {
      // แปลงรูปเป็น base64
      final String base64Image = base64Encode(imageBytes);
      final String defaultIMG = await convertImageToBase64(widget.imagePath);
      print('defaultIMG ${defaultIMG}');
      // Get max/min values
      final maxMinValues = getMaxMinValues();
      final maxDbm = maxMinValues['Max_dBm']!;
      final minDbm = maxMinValues['Min_dBm']!;
      int mapID = generateUniqueMapID();
      int versID = generateUniqueverID();

      // สร้าง version data
      final Map<String, dynamic> versionData = {
        'Map_id': mapID,
        'Version_id': versID, 
        // 'User_id': widget.userId, // 
        'name': widget.name, // ชื่อ
        'location': widget.location, // ชื่อ
        'BSSID':widget.accessPoint.bssid, // BSSID
        'SSID': widget.accessPoint.ssid, // SSID
        'frequency': widget.accessPoint.frequency, // frequency
        'Location': widget.location, // location
        'ImageData': defaultIMG, // imageData (base64)
        'Description': 'asd', // description
        'Max_dBm': maxDbm, // maxDbm
        'Min_dBm': minDbm, // minDbm
        'Image': base64Image, // image
        'Created_at': DateTime.now().toIso8601String(), // createdAt
      };
  
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();
      
      // ดึงข้อมูล versions ที่มีอยู่
      List<String> savedVersions = prefs.getStringList('saved_versions') ?? [];
      
      // เพิ่ม version ใหม่
      savedVersions.add(jsonEncode(versionData));
      
      // บันทึกลง SharedPreferences
      await prefs.setStringList('saved_versions', savedVersions);
      
      // แสดงข้อมูลที่บันทึก
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved successfully')),
      );
      
      Navigator.of(context).pop(true); // กลับไปหน้าก่อนหน้านี้
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture screenshot')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving version: $e')),
    );
    print('Error saving version: $e');
  }
}

  
 

  
// Future<void> _saveVersion(BuildContext context,String image2base64) async {
//   String? token = await _getToken();
//   final maxMinValues = getMaxMinValues();
//   final maxDbm = maxMinValues['Max_dBm']!;
//   final minDbm = maxMinValues['Min_dBm']!;
//    String? base64Image;

//       // แปลงรูปภาพเป็น base64
//       if (widget.imagePath != null) {
//         try {
//           base64Image = await convertImageToBase64(widget.imagePath);
//         } catch (e) {
//           print('ข้อผิดพลาดในการแปลงรูปภาพ: $e');
//           return;
//         }
//       } else {
//         print('ข้อผิดพลาด: imagePath เป็น null');
//         return;
//       }
//   // Prepare data to be sent in POST request
//   final Map<String, dynamic> data = {
//     'Map_id': widget.mapID,
//     'Created_at': DateTime.now().toIso8601String(),
//     'description': 'asd', // Ensure this field is not null
//     'Max_dBm': maxDbm,
//     'Min_dBm': minDbm,
//     'Image': image2base64, // Ensure this field is not null
//   };

//   try {
//     // Send POST request
//     final response = await http.post(
//       Uri.parse('http://${_ipAddress}:${_port}/api/version'),
//       headers: {
//         'Content-Type': 'application/json', // Ensure content type is set
//         'Authorization': 'Bearer $token', // Add your authorization token if needed
//       },
//       body: jsonEncode(data),
//     );

//     // Check the response status
//     if (response.statusCode == 201) {
//       // Successfully created the version
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   SnackBar(content: Text('Version created successfully')),
//       // );
//       Navigator.of(context).pop(true); // Close the screen and return true
//     } else {
//       // Failed to create the version
//       final responseData = jsonDecode(response.body);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to create version: ${responseData['error']}')),
//       );
//     }
//   } catch (e) {
//     // Handle error
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error: $e')),
//     );
//   }
// }


  void _deleteProject(int mapId) async {
    String? token = await _getToken();
    final response = await http.delete(
      Uri.parse('http://${_ipAddress}:${_port}/api/maps/${mapId}'),
      headers: {
        'Authorization': 'Bearer ${token}',
      },
    );

    if (response.statusCode == 200) {}
  }

  Widget _buildTopContainer(accessPoint, String location, String Name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50],
        ),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.red.withOpacity(0.9),
        //     // spreadRadius: 30,
        //     // blurRadius: 5\,
        //     // offset: Offset(0, 5),
        //   ),
        // ],
      ),
      child: ClipRRect(
        child: Stack(
          children: [
            Positioned(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              accessPoint.ssid,
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5.0),
                            Text(
                              accessPoint.bssid,
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildSignalStrengthIndicator(accessPoint.level),
                    ],
                  ),
                  SizedBox(height: 2.0),
                  Expanded(
                    child: _buildInfoGrid([
                      _buildInfoItem(
                          'Protocol', getProtocolName(accessPoint.standard)),
                      _buildInfoItem('Capabilities', accessPoint.capabilities),
                      _buildInfoItem(
                          'Frequency', '${accessPoint.frequency} MHz'),
                      _buildInfoItem('Channel',
                          getWifiChannelInfo(accessPoint.frequency.toDouble())),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getProtocolName(WiFiStandards standard) {
    switch (standard) {
      case WiFiStandards.unkown:
        return "Unknown";
      case WiFiStandards.legacy:
        return "802.11a/b/g";
      case WiFiStandards.n:
        return "802.11n";
      case WiFiStandards.ac:
        return "802.11ac";
      case WiFiStandards.ax:
        return "802.11ax";
      case WiFiStandards.ad:
        return "802.11ad";
      default:
        return "Unknown";
    }
  }

  Widget _buildInfoGrid(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio:
              (constraints.maxWidth / 2) / 50, // Adjust this value as needed
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: items,
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade900,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color getSignalColor(int level) {
    if (level >= -30) return Colors.green;
    if (level >= -67) return Colors.lightGreen;
    if (level >= -70) return Colors.yellow;
    if (level >= -80) return Colors.orange;
    if (level >= -90) return Colors.deepOrange;
    return Colors.red; // Default color if no other condition is met
  }

  IconData getSignalIcon(int level) {
    if (level >= -40) return Icons.signal_wifi_4_bar;
    if (level >= -67) return Icons.network_wifi_3_bar;
    if (level >= -70) return Icons.network_wifi_2_bar;
    if (level >= -80) return Icons.network_wifi_1_bar;
    return Icons.signal_wifi_off; // Default icon if no other condition is met
  }

  Widget _buildSignalStrengthIndicator(int level) {
    Color color = getSignalColor(level);
    IconData icon = getSignalIcon(level);

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }

  String getWifiChannelInfo(double frequency) {
    if (frequency >= 2412 && frequency <= 2484) {
      // Calculate primary channel for 2.4 GHz band
      int primaryChannel = ((frequency - 2407) ~/ 5);

      return "$primaryChannel"; // Only return primary channel for 2.4 GHz band
    } else if (frequency >= 5170 && frequency <= 5825) {
      // Calculate primary channel for 5 GHz band
      int primaryChannel = ((frequency - 5170) ~/ 5) + 34;
      return "$primaryChannel"; // Only return primary channel for 5 GHz band
    } else if (frequency >= 5925 && frequency <= 7125) {
      // Calculate primary channel for 5 GHz extended band
      int primaryChannel = ((frequency - 5925) ~/ 5) + 1;
      return "$primaryChannel"; // Only return primary channel for 5 GHz extended band
    } else {
      return "-1"; // Return -1 for frequencies outside supported ranges
    }
  }

  Widget _buildMapDetail(BuildContext context) {
    final imagePath = widget.imagePath;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white],
        ),
      ),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: File(imagePath).existsSync()
          ? Image.file(
              File(imagePath),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.contain,
            )
          : Image.asset(
              'assets/images/map3.png',
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.contain,
            ),
    );
  }

Widget _buildBottomContainer() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Colors.blue.shade50],
      ),
      // boxShadow: [
      //   BoxShadow(
      //     color: Colors.grey.withOpacity(0.2),
      //     spreadRadius: 5,
      //     blurRadius: 5,
      //     offset: Offset(0, 3),
      //   ),
      // ],
    ),
    child: Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            mainAxisAlignment: MainAxisAlignment.center,
           children: [
  _buildImage('assets/images/bg1.png'),
  // SizedBox(height: MediaQuery.of(context).size.height * 0.01),
  if (currentSignalStrength <= -100)
    _buildText('Unusable')
  else
    _buildText('${currentSignalStrength.toDouble()}'),
  SizedBox(height: 10),
  _buildPinButton(),
],
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Image.asset('assets/images/logo1.png', width: 100, height: 50), // Adjust the size as needed
          ),
        ),
      ],
    ),
  );
}
Widget _buildImage(String imagePath) {
  // if (!isVisiblePin) {
  //   return SizedBox.shrink(); 
  // }
  return Padding(
    padding: EdgeInsets.all(0.0), // Adjust padding as needed
    child: Image.asset(
      imagePath,
      // width: 300,
      // height: 100,
      fit: BoxFit.contain, // Adjust fit as needed
    ),
  );
}


  Widget _buildText(String text) {
      if (!isVisiblePin) {
    return SizedBox.shrink(); 
  }
    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey,
          fontSize: MediaQuery.of(context).size.width * 0.06,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

 Widget _buildPinButton() {
  if (!isVisiblePin) {
    return SizedBox.shrink();
  }

  return ElevatedButton(
    onPressed: () async {
      // แสดงวงกลมหมุนบนปุ่ม
      setState(() {
        isLoading = true;
      });

      // รอ 5 วินาที
      await Future.delayed(Duration(seconds: 4));

      // เพิ่มวงกลมใหม่และซ่อนวงกลมหมุน
      setState(() {
        isLoading = false;
        Color circleColor = _getColorForSignalStrength(currentSignalStrength);
        circles.add(CustomCircle(
            pinPosition, circleColor, MediaQuery.of(context).size));
      });
    },
    style: ElevatedButton.styleFrom(
      elevation: 5,
      minimumSize: Size(
        70.0 * MediaQuery.of(context).size.width * 0.003,
        45.0 * MediaQuery.of(context).size.height * 0.001,
      ),
    ),
    child: isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Image.asset(
            'assets/images/pin.png',
            width: 55.0 * MediaQuery.of(context).size.width * 0.003,
            height: 55.0 * MediaQuery.of(context).size.height * 0.001,
          ),
  );
}

  Widget _buildMapDetailWithCircles(BuildContext context) {
    return Stack(
      children: [
        _buildMapDetail(context),
        for (CustomCircle circle in circles) circle,
        Positioned(
          left: pinPosition.dx,
          top: pinPosition.dy,
          child: _buildPinImage(),
        ),
      ],
    );
  }

Widget _buildPinImage() {
  if (!isVisiblePin) {
    return SizedBox.shrink(); 
  }

  return GestureDetector(
    onPanUpdate: (details) {
      updatePinPosition(context, details.delta, _getMapDetailConstraints());
    },
    child: Image.asset(
      'assets/images/pin.png',
      width: 70.0 * MediaQuery.of(context).size.width * 0.0025,
      height: 60.0 * MediaQuery.of(context).size.height * 0.002,
    ),
  );
}


  void updatePinPosition(
      BuildContext context, Offset delta, BoxConstraints constraints) {
    final double maxWidth = constraints.maxWidth;
    final double maxHeight = constraints.maxHeight;

    double minX = -20;
    double minY = 0;

    setState(() {
      double maxX = maxWidth;
      double maxY = maxHeight;

      pinPosition = Offset(
        (pinPosition.dx + delta.dx).clamp(minX, maxX),
        (pinPosition.dy + delta.dy).clamp(minY, maxY),
      );

      // print('Pin Position: x=${pinPosition.dx}, y=${pinPosition.dy}');
    });
  }

void updateSignalStrength() {
  double updatedSignalStrength =
      widget.updateSignalStrength(widget.accessPoint, currentSignalStrength);


  setState(() {
    if (updatedSignalStrength > -100) {
      // WiFi พบ และมีสัญญาณที่วัดได้
      currentSignalStrength = updatedSignalStrength;
    } else {
      // WiFi ไม่พบหรือสัญญาณอ่อนมาก
    currentSignalStrength = -101;
    }

    // เก็บค่าความแรงสัญญาณลงใน ChkDbm
    ChkDbm.add(currentSignalStrength);

    // อัปเดต UI หรือ heatmap ตามค่า currentSignalStrength
    updateHeatmap(currentSignalStrength);
  });
}

void updateHeatmap(double signalStrength) {
  // ตรวจสอบว่า signalStrength อยู่ในช่วงที่ต้องการหรือไม่
  if (signalStrength > -100) {
    // อัปเดต heatmap สำหรับสัญญาณปกติ
    // เพิ่มโค้ดสำหรับอัปเดต heatmap ของคุณที่นี่
  } else {
    // อัปเดต heatmap สำหรับกรณีไม่มีสัญญาณ
    // เช่น เปลี่ยนสีหรือความโปร่งใสของจุดที่เกี่ยวข้องบน heatmap
  }
}

  Color _getColorForSignalStrength(double level) {
    if (level >= -30) {
      return Colors.green.withOpacity(0.8); // Excellent
    } else if (level >= -67) {
      return Colors.lightGreen.withOpacity(0.8); // Very Good
    } else if (level >= -70) {
      return Colors.yellow.withOpacity(0.8); // Okay
    } else if (level >= -80) {
      return Colors.orange.withOpacity(0.8); // Not Good
    } else if (level >= -90) {
      return Colors.red.withOpacity(0.8); // Unusable
    } else {
      return Colors.grey.withOpacity(0.8);
    }
  }

  BoxConstraints _getMapDetailConstraints() {
    double maxWidth = MediaQuery.of(context).size.width;
    double maxHeight = MediaQuery.of(context).size.height;
    return BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight);
  }
}

class CustomCircle extends StatelessWidget {
  final Offset position;
  final Color color;
  final Size screenSize;

  CustomCircle(this.position, this.color, this.screenSize);

  @override
  Widget build(BuildContext context) {
    double circlePositionX = position.dx + (60.0 * screenSize.width * 0.0015);
    double circlePositionY = position.dy + (60.0 * screenSize.height * 0.0015);

    return Positioned(
      left: circlePositionX,
      top: circlePositionY,
      child: CustomPaint(
        painter: CirclePainter(color, screenSize),
      ),
    );
  }
}

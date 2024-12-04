import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:screenshot/screenshot.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:wimapgen/menu/custompaint.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wimapgen/model/user_model.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:wimapgen/config/hostname.dart';

class ContinueHeatmapPage extends StatefulWidget {
  final String location;
  final String name;
  final String bssid;
  final String image;
  final int mapId;
  final String ssid;
  final int frequency;
  final String imagePath;

  ContinueHeatmapPage({
    required this.location,
    required this.name,
    required this.bssid,
    required this.image,
    required this.mapId,
    required this.ssid,
    required this.frequency,
    required this.imagePath,
  });

  @override
  _ContinueHeatmapPageState createState() => _ContinueHeatmapPageState();
}

class _ContinueHeatmapPageState extends State<ContinueHeatmapPage> {
  bool isLoading = false;
  final ScreenshotController screenshotController = ScreenshotController();
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  Timer? _scanTimer;
  Offset pinPosition = Offset.zero;
  List<CustomCircle> circles = [];
  bool isVisiblePin = true;
  late Uint8List imageBytes;
  User? _user;
  List<double> ChkDbm = [];
  bool _isSaving = false;
  bool isLoadingBT = false;
  String _ipAddress = '';
  int _port = 0;
  
  @override
  void initState() {
    super.initState();
    _loadConnectionDetails();
    imageBytes = base64Decode(widget.image);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        pinPosition = getCenterPosition(context);
      });
    });
    _startScanning();
    // print(widget.mapId);
  }

  
    Future<void> _loadConnectionDetails() async {
    
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {

    _ipAddress = prefs.getString('ip_address') ?? '192.168.136.20';
    _port = prefs.getInt('port') ?? 3000;
    
    
  });}

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }
Future<bool> _onWillPop(BuildContext context) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Save Changes?'),
        content: Text('Do you want to save the changes before leaving?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Discard'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(false);
              await _captureAndSaveToDatabase();
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );

  if (result == true) {
    Navigator.of(context).pop();
  }

  return false;
}
  void _startScanning() {
    _scanTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // print('scan');
      _startListeningToScanResults();
    });
  }

  Future<void> _startListeningToScanResults() async {
    if (!mounted) return;
    try {
      var locationStatus = await Permission.location.request();
      if (locationStatus != PermissionStatus.granted) {
        print('Location permission denied');
        return;
      }
      List<WiFiAccessPoint> result =
          await WiFiScan.instance.getScannedResults();
      _updateAccessPoints(result);
      bool scanSuccess = await WiFiScan.instance.startScan();
      if (scanSuccess) {
        List<WiFiAccessPoint> result =
            await WiFiScan.instance.getScannedResults();
        _updateAccessPoints(result);
      }
    } catch (e) {
      print('Error during scan: $e');
    }
  }

void _updateAccessPoints(List<WiFiAccessPoint> result) {
    if (!mounted) return;
    // print(isLoading);
    // เพิ่ม OR condition กับค่า isLoading เดิม
    isLoading = isLoading || accessPoints.where((ap) => ap.bssid == widget.bssid).isEmpty;
    // print(isLoading);
    setState(() {
      accessPoints = result;
      accessPoints.sort((a, b) => b.level.compareTo(a.level));
    
      for (var ap in accessPoints) {
        var currentLevel = ap.level.toDouble();
        var bssid = ap.bssid;
        var ssid = ap.ssid;
        if(widget.bssid == ap.bssid){
          ChkDbm.add(ap.level.toDouble());
        }
      }
    });
}
  Future<void> _captureAndSaveToDatabase() async {
    try {
      setState(() {
        isVisiblePin = false;
      });
      final Uint8List? imageBytes = await screenshotController.capture();
      if (imageBytes != null) {
        // แปลง Uint8List เป็น Base64 string
        String base64Image = base64Encode(imageBytes);
        print(base64Image);
        // บันทึกลง database
        await _saveVersion(context);

        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Image saved to database successfully')),
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture widget')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
      });
    }
  }

Map<String, dynamic> getMaxMinValues() {
  double maxSignalStrength = double.negativeInfinity;
  double minSignalStrength = double.infinity;

  print('ChkDbm: $ChkDbm'); // ตรวจสอบค่าใน ChkDbm

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
      // final String defaultIMG = await convertImageToBase64(widget.imagePath);
      // print('defaultIMG ${defaultIMG}');
      // Get max/min values
      final maxMinValues = getMaxMinValues();
      final maxDbm = maxMinValues['Max_dBm']!;
      final minDbm = maxMinValues['Min_dBm']!;
    
      int versID = generateUniqueverID();

      // สร้าง version data
      final Map<String, dynamic> versionData = {
        'Map_id': widget.mapId,
        'Version_id': versID, 
        // 'User_id': widget.userId, // 
        'name': widget.name, // ชื่อ
        'location': widget.location, // ชื่อ
        'BSSID':widget.bssid, // BSSID
        'SSID': widget.ssid, // SSID
        'frequency': widget.frequency, // frequency
        'Location': widget.location, // location
        'ImageData': widget.imagePath, // imageData (base64)
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

  

// Future<void> _saveVersion(BuildContext context, String image2base64) async {
//   setState(() {
//     _isSaving = true;
//   });

//   String? token = await _getToken();
//   final maxMinValues = getMaxMinValues();
//   final maxDbm = maxMinValues['Max_dBm']!;
//   final minDbm = maxMinValues['Min_dBm']!;

//   final Map<String, dynamic> data = {
//     'Map_id': widget.mapId,
//     'Created_at': DateTime.now().toIso8601String(),
//     'description': 'asd',
//     'Max_dBm': maxDbm,
//     'Min_dBm': minDbm,
//     'Image': image2base64,
//   };

//   try {
//     final response = await http.post(
//       Uri.parse('http://${_ipAddress}:${_port}/api/version'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//       body: jsonEncode(data),
//     );

//     if (response.statusCode == 201 || response.statusCode == 200) {
//       print('successfully');
//       Navigator.of(context).pop(true);
//     } else {
//       final responseData = jsonDecode(response.body);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to create version: ${responseData['error']}')),
//       );
//     }
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error: $e')),
//     );
//   } finally {
//     if (mounted) {
//       setState(() {
//         _isSaving = false;
//       });
//     }
//   }
// }

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
    // print(base64Image);
    return base64Image;
  }
  
  @override
Widget build(BuildContext context) {
  WiFiAccessPoint? matchedAccessPoint =
      accessPoints.where((ap) => ap.bssid == widget.bssid).isNotEmpty
          ? accessPoints.firstWhere((ap) => ap.bssid == widget.bssid)
          : null;

  return PopScope(
    canPop: false,
    onPopInvoked: (didPop) async {
      if (didPop) return;
      await _onWillPop(context);
    },
    child: Stack(
      children: [
        Scaffold(
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
              if (!isLoading)
                Container(
                  color: Colors.white,
                  child: Center(
                    child: Image.asset(
                      'assets/images/loading.gif',
                      width: 200,
                      height: 200,
                    ),
                  ),
                )
              else
                Screenshot(
                  controller: screenshotController,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _buildMapDetailWithCircles(context),
                      ),
                      if (matchedAccessPoint != null) ...[
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: MediaQuery.of(context).size.height * 0.26,
                          child: _buildTopContainer(
                              matchedAccessPoint, widget.location, widget.name),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: MediaQuery.of(context).size.height * 0.26,
                          child: _buildBottomContainer(matchedAccessPoint),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.5),
            // child: Center(
            //   child: Image.asset(
            //     'assets/images/loading-unscreen.gif',
            //     width: 200,
            //     height: 200,
            //   ),
            // ),
          ),
      ],
    ),
  );
}
  Offset getCenterPosition(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 3;
    return Offset(centerX, centerY);
  }

  Widget _buildTopContainer(
      WiFiAccessPoint accessPoint, String location, String Name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50],
        ),
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

  Widget _buildBottomContainer(WiFiAccessPoint accessPoint) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50],
        ),
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
                _buildText(accessPoint.level.toString()),
                SizedBox(height: 10),
                _buildPinButton(accessPoint),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Image.asset('assets/images/logo1.png',
                  width: 100, height: 50),
            ),
          ),
        ],
      ),
    );
  }



Widget _buildPinButton(WiFiAccessPoint accessPoint) {
  if (!isVisiblePin) {
    return SizedBox.shrink();
  }
  return ElevatedButton(
    onPressed: () async {
      // แสดงวงกลมหมุนบนปุ่ม
      setState(() {
        isLoadingBT = true;
      });

      // รอ 5 วินาที
      await Future.delayed(Duration(seconds: 4));

      // เพิ่มวงกลมใหม่และซ่อนวงกลมหมุน
      setState(() {
        isLoadingBT = false;
        Color circleColor =
            _getColorForSignalStrength(accessPoint.level.toDouble());
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
    child: isLoadingBT
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

  Color _getColorForSignalStrength(double level) {
    if (level >= -30) {
      return Colors.green.withOpacity(0.8);
    } else if (level >= -67) {
      return Colors.lightGreen.withOpacity(0.8);
    } else if (level >= -70) {
      return Colors.yellow.withOpacity(0.8);
    } else if (level >= -80) {
      return Colors.orange.withOpacity(0.8);
    } else if (level >= -90) {
      return Colors.red.withOpacity(0.8);
    } else {
      return Colors.grey.withOpacity(0.8);
    }
  }

  Widget _buildImage(String imagePath) {
    return Padding(
      padding: EdgeInsets.all(0.0),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
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

  Widget _buildInfoGrid(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: (constraints.maxWidth / 2) / 50,
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
    return Colors.red;
  }

  IconData getSignalIcon(int level) {
    if (level >= -40) return Icons.signal_wifi_4_bar;
    if (level >= -67) return Icons.network_wifi_3_bar;
    if (level >= -70) return Icons.network_wifi_2_bar;
    if (level >= -80) return Icons.network_wifi_1_bar;
    return Icons.signal_wifi_off;
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
      int primaryChannel = ((frequency - 2407) ~/ 5);
      return "$primaryChannel";
    } else if (frequency >= 5170 && frequency <= 5825) {
      int primaryChannel = ((frequency - 5170) ~/ 5) + 34;
      return "$primaryChannel";
    } else if (frequency >= 5925 && frequency <= 7125) {
      int primaryChannel = ((frequency - 5925) ~/ 5) + 1;
      return "$primaryChannel";
    } else {
      return "-1";
    }
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

  Widget _buildMapDetail(BuildContext context) {
    return Center(
      child: Image.memory(imageBytes, fit: BoxFit.cover),
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

    double minX = 0;
    double minY = 0;

    setState(() {
      double maxX = maxWidth;
      double maxY = maxHeight;

      pinPosition = Offset(
        (pinPosition.dx + delta.dx).clamp(minX, maxX),
        (pinPosition.dy + delta.dy).clamp(minY, maxY),
      );
    });
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'create_heatmap.dart';
import 'heatmap_project.dart';
import 'loginPage.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wimapgen/model/user_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wimapgen/config/hostname.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:intl/intl.dart';
import 'package:wimapgen/menu/profilepage.dart';
import 'package:wimapgen/menu/editUserInformation.dart';
import 'package:wimapgen/menu/generateUser.dart';


class WifiInfoScreen extends StatefulWidget {
  final bool isLoggedIn;
  final User? user;

  const WifiInfoScreen({Key? key, required this.isLoggedIn, this.user})
      : super(key: key);

  @override
  _WifiInfoScreenState createState() => _WifiInfoScreenState();
}

class _WifiInfoScreenState extends State<WifiInfoScreen>
    with WidgetsBindingObserver {
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  late double signalStrength;
  double maxSignalStrength = 100.0;
  WiFiAccessPoint? selectedAccessPoint;
  Timer? _scanTimer;
  int _selectedIndex = 0;
  bool _isScanning = false;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  bool _isLoadingById = true;
  User? _user;
  User? _isME;
  int userID = 0;
  final picker = ImagePicker();
  String? imagePath;
  List<User> _users = [];
  int? selectedUserIndex = 0;
  int userId = 0;
  bool isStopFetchUsers = false;
  Map<String, bool> selectedAccessPoints = {};
  Map<String, Map<String, List<double>>> levelsByBSSID = {};
  bool _isGridView = true;
  int _currentPage = 0;
  int _currentPageUsers = 0;
  String _ipAddress = '';
  int _port = 0;
  int MapID = 0;
  String? Fname = '';
  String? Lname = '';
  String? image = '';
  String? email = '';
  String? description = '';
  int? uid;
  int? role;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _loadConnectionDetails();
    // _checkSession();
    // _checkDataUser();
    signalStrength = 0.0;
    _startScanning();
    getUserById();
initialize();
    _isLoggedIn = widget.isLoggedIn;
    initializeSelectedAccessPoints();
  }

  Future<void> _loadConnectionDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipAddress = prefs.getString('ip_address') ?? '192.168.136.20';
      _port = prefs.getInt('port') ?? 3000;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopScanning();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopScanning();
      print('paused');
    } else if (state == AppLifecycleState.resumed) {
      _startScanning();
      print('resumed');
    }
  }

  void initializeSelectedAccessPoints() {
    for (var ap in accessPoints) {
      selectedAccessPoints[ap.bssid] ??= false;
    }
  }

  void _startScanning() {
    if (!_isScanning) {
      _isScanning = true;
      _scanTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _startListeningToScanResults();
      });
    }
  }

  Future<void> _startListeningToScanResults() async {
    try {
      var locationStatus = await Permission.location.request();
      if (locationStatus != PermissionStatus.granted) {
        print('Location permission denied');
        return;
      }

      List<WiFiAccessPoint> result;
      bool scanSuccess = await WiFiScan.instance.startScan();

      if (scanSuccess) {
        result = await WiFiScan.instance.getScannedResults();
      } else {
        result = await WiFiScan.instance.getScannedResults();
      }

      if (!mounted) return; // Check if the widget is still in the tree

      _updateAccessPoints(result);
    } catch (e) {
      print('Error during scan: $e');
    }
  }

  void _updateAccessPoints(List<WiFiAccessPoint> result) {
    setState(() {
      accessPoints = result;
      accessPoints.sort((a, b) => b.level.compareTo(a.level));
      _isLoading = false;
    });

    _updateLevelsByBSSID();
    _updateSelectedAccessPoints();
  }

  void _updateLevelsByBSSID() {
    Set<String> currentBSSIDs = Set();

    for (var ap in accessPoints) {
      var currentLevel = ap.level.toDouble();
      var bssid = ap.bssid;
      var ssid = ap.ssid;

      currentBSSIDs.add(bssid);

      levelsByBSSID.putIfAbsent(bssid, () => {});
      levelsByBSSID[bssid]!.putIfAbsent(ssid, () => []);

      var levels = levelsByBSSID[bssid]![ssid]!;

      if (levels.isEmpty || currentLevel != levels.last) {
        levels.add(currentLevel);

        if (levels.length >= 25) {
          levels.removeAt(0);
        }
      }
    }

    levelsByBSSID.removeWhere((bssid, _) => !currentBSSIDs.contains(bssid));
  }

  void _updateSelectedAccessPoints() {
    for (var ap in accessPoints) {
      selectedAccessPoints[ap.bssid] ??= false;
    }
  }

  double updateSignalStrength(
      WiFiAccessPoint selectedAccessPoint, double currentSignalStrength) {
    double updatedSignalStrength = -150; // เริ่มต้นด้วย 0 เสมอ

    if (mounted) {
      setState(() {
        if (selectedAccessPoint != null) {
          int index = accessPoints.indexWhere((ap) =>
              ap.ssid == selectedAccessPoint.ssid &&
              ap.bssid == selectedAccessPoint.bssid);
          if (index != -1) {
            // พบ Access Point ที่เลือก อัปเดตค่า signal strength
            updatedSignalStrength = accessPoints[index].level.toDouble();
          }
          // ถ้าไม่พบ index, updatedSignalStrength จะเป็น 0 ตามที่กำหนดไว้ข้างบน
        }
        // ถ้าไม่มี selectedAccessPoint, updatedSignalStrength จะเป็น 0 เช่นกัน

        print('update dBm in wifiinfopage ${updatedSignalStrength}');
      });
    }

    return updatedSignalStrength;
  }

  void _stopScanning() {
    // Uncomment these lines if you want to actually stop scanning
    // _scanTimer?.cancel();
    // _isScanning = false;
  }

  Future<String?> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token == null) {
      setState(() {
        _isLoggedIn = false;
        isStopFetchUsers = false;
      });
    } else {
      setState(() {
        _isLoggedIn = true;
        isStopFetchUsers = true;
      });
    }
    return token;
  }

  Future<void> _checkDataUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    if (userData != null) {
      setState(() {
        _user = User.fromJson(json.decode(userData));
        _isME = User.fromJson(json.decode(userData));

        Fname = _isME?.firstName;
        Lname = _isME?.lastName;
        image = _isME?.image;
        email = _isME?.email;
        description = _isME?.description;
        uid = _isME?.userId;
        role = _isME?.role;
      });
    }
  }

  Future<void> _removeSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    setState(() {
      _isLoggedIn = false;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo1.png', height: 50),
        backgroundColor: Colors.white,
      ),
      drawer: _buildDrawer(_isLoggedIn),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildAccessPointList(),
          _buildTimeGraph(),
          _buildUserList(context),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildDrawer(bool isLoggedIn) {
    return Drawer(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.grey[300],
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildDrawerHeader(isLoggedIn)),
            SliverList(
              delegate: SliverChildListDelegate([
                _buildListTile(
                    Icons.home, 'Main', () => Navigator.pop(context)),
                if (!isLoggedIn) ...[
                  _buildListTile(Icons.list_alt_rounded, 'My projects', () {
                     Navigator.of(context).pop();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HeatmapProjectPage()));
                  }),
                  // _buildListTile(Icons.person, 'My profile', () {
                  //   _navigateToProfile();
                  // }),
                ],
                const AboutListTile(
                  icon: Icon(Icons.info),
                  applicationName: 'WiMapGen',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2023 CSMSU',
                  child: Text('About app'),
                ),
                // _buildListTile(
                //   Icons.login_outlined,
                //   isLoggedIn ? 'Logout' : 'Login',
                //   () {
                //     _removeSession();
                //     _removeUser();
                //     setState(() {
                //       _selectedIndex = 0;
                //     });
                //     Navigator.pushReplacement(
                //       context,
                //       MaterialPageRoute(
                //           builder: (context) => const LoginPage()),
                //     );
                //   },
                // ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          firstName: Fname,
          lastName: Lname,
          image: image,
          userId: uid.toString(),
          description: description,
        ),
      ),
    );
    if (result == true) {
      getUserById();
    }
  }
  
Widget _buildDrawerHeader(bool isLoggedIn) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
             Color(0xFF2C3E50),  // Deep blue-gray
          Color(0xFF3498DB),  // Bright blue
          Color(0xFF2980B9),  // Strong blue
        ],
      ),
    ),
    child: DrawerHeader(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: isLoggedIn
          ? Stack(
              children: [
                // Background Design Elements
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                // Main Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: MemoizedProfileImage(imageData: image),
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${Fname ?? ''} ${Lname ?? ''}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 3.0,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    email ?? '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_isME?.description != null &&
                          _isME!.description.isNotEmpty)
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(10),
                            child: SingleChildScrollView(
                              child: Text(
                                description!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  height: 1.5,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Logo
                Positioned(
                  bottom: 8,
                  right: -15,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/logo1.png',
                      width: 100,
                      height: 30,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              child: Center(
                child: Image.asset(
                  'assets/images/logo1.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
    ),
  );
}
  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildProfileImage() {
    final imageProvider = image != null
        ? MemoryImage(base64Decode(image!))
        : AssetImage('assets/images/person1.png') as ImageProvider;

    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.orange,
      backgroundImage: imageProvider,
    );
  }

  @override
  void _removeUser() {
    print('Before removing user line 284: ${_user?.firstName}');
    setState(() {
      _user = null; // Set user to null to remove user information
      print('After removing user line 284: ${_user?.firstName}');
    });
  }

  Widget _buildAccessPointList() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isLoading
          ? Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Image.asset(
                  'assets/images/loading.gif',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            )
          : _buildPaginatedList(),
    );
  }

  Widget _buildPaginatedList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ประมาณความสูงของแต่ละรายการ (อาจต้องปรับตามความสูงจริงของ _buildWifiTile)
        double estimatedItemHeight = 80.0;

        // คำนวณจำนวนรายการต่อหน้าตามความสูงที่มีอยู่
        int itemsPerPage =
            (constraints.maxHeight / estimatedItemHeight).floor();

        // ตรวจสอบให้แน่ใจว่าแสดงอย่างน้อย 1 รายการ
        itemsPerPage = itemsPerPage > 0 ? itemsPerPage : 1;

        // คำนวณจำนวนหน้าทั้งหมด
        int totalPages = (accessPoints.length / itemsPerPage).ceil();

        // กำหนดเริ่มต้นและสิ้นสุดสำหรับรายการในหน้าปัจจุบัน
        int startIndex = _currentPage * itemsPerPage;
        int endIndex = (startIndex + itemsPerPage < accessPoints.length)
            ? startIndex + itemsPerPage
            : accessPoints.length;

        return ListView(
          children: [
            // สร้างรายการ Wi-Fi tiles
            ...List.generate(
              endIndex - startIndex,
              (index) => _buildWifiTile(startIndex + index),
            ),
            // แสดงตัวควบคุมการนำทางหน้าถ้ามีรายการมากกว่าหนึ่งหน้า
            if (accessPoints.length > itemsPerPage)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ปุ่มย้อนกลับหน้า
                    GestureDetector(
                      onTap: _currentPage > 0 ? _previousPage : null,
                      child: Text(
                        '<<',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _currentPage > 0 ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // แสดงหมายเลขหน้าปัจจุบันและจำนวนหน้าทั้งหมด
                    Text('${_currentPage + 1}/$totalPages'),
                    SizedBox(width: 16),
                    // ปุ่มไปหน้าถัดไป
                    GestureDetector(
                      onTap: _currentPage < totalPages - 1 ? _nextPage : null,
                      child: Text(
                        '>>',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _currentPage < totalPages - 1
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _nextPage() {
    setState(() {
      _currentPage++;
    });
  }

  void _previousPage() {
    setState(() {
      _currentPage--;
    });
  }

  void _nextPageUser() {
    setState(() {
      _currentPageUsers++;
    });
  }

  void _previousPageUser() {
    setState(() {
      _currentPageUsers--;
    });
  }

  double calculateDistance(int rssi) {
    // Constants
    double A = -35; // Calibrated RSSI value at 1 meter distance
    double n = 2.5; // Path loss exponent (average between indoor and outdoor)

    // Calculate distance
    double ratio = (A - rssi) / (10 * n);
    double distance = pow(10, ratio).toDouble();

    // Apply adaptive correction factor
    double correctionFactor;
    if (rssi > -50) {
      correctionFactor = 0.85;
    } else if (rssi > -60) {
      correctionFactor = 0.95;
    } else if (rssi > -70) {
      correctionFactor = 1.05;
    } else if (rssi > -80) {
      correctionFactor = 1.15;
    } else {
      correctionFactor = 1.25;
    }

    distance *= correctionFactor;

    // Apply limits to prevent unrealistic values
    // distance = distance.clamp(0.5, 75.0);

    // Round to two decimal places
    return double.parse(distance.toStringAsFixed(2));
  }

static Map<String, String>? _vendorMap;

  static Future<void> initialize() async {
    if (_vendorMap != null) return;

    try {
      final jsonString = await rootBundle.loadString('assets/vendor/oui.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _vendorMap = {};
      
      for (var item in jsonList) {
        final entry = item['RegistryAssignmentOrganization NameOrganization Address'] as String;
        final parts = entry.split('\t');
        
        // Check if we have at least 3 parts (Registry, MAC, Organization)
        if (parts.length >= 3) {
          final macPrefix = parts[1].toUpperCase(); // Get the MAC prefix
          
          // Extract organization name, removing any quotes
          String organizationName = parts[2].replaceAll('"', '');
          
          // If there's an address included, we'll just use the organization name
          if (organizationName.contains('\\')) {
            organizationName = organizationName.split('\\')[0];
          }
          
          _vendorMap![macPrefix] = organizationName.trim();
        }
      }
    } catch (e) {
      print('Error loading MAC vendor database: $e');
      _vendorMap = {};
    }
  }

  static String getVendorName(String macAddress) {
    if (_vendorMap == null) {
      return 'Database not loaded';
    }

    // Convert MAC address to standardized format
    final prefix = macAddress
        .replaceAll(':', '')
        .replaceAll('-', '')
        .toUpperCase()
        .substring(0, 6);

    return _vendorMap![prefix] ?? 'Unknown Vendor';
  }

  // Debug method
  static void printDatabase() {
    print('Vendor database entries: ${_vendorMap?.length ?? 0}');
    _vendorMap?.entries.take(5).forEach((entry) {
      print('${entry.key}: ${entry.value}');
    });
  }
  Widget _buildWifiTile(int index) {
  final accessPoint = accessPoints[index];
  final isWpa3 = accessPoint.capabilities.contains("RSN-SAE");
  final isWpa2 = accessPoint.capabilities.contains("WPA2-PSK");
  final isWpa = accessPoint.capabilities.contains("WPA");
  final isLocked = isWpa || isWpa2 || isWpa3;

  final distance = calculateDistance(accessPoint.level);
  final dBmValue = accessPoint.level;
  final signalColor = _getColorForSignalStrength(accessPoint.level);
  final signalStrength = _getSignalStrengthText(accessPoint.level);
  final vendorName = getVendorName(accessPoint.bssid);

  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAccessPointDialog(context, accessPoint),
        borderRadius: BorderRadius.circular(16),
        child: Hero(
          tag: 'wifi-${accessPoint.bssid}',
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Animated Signal Indicator
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1500),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: _buildAnimatedSignalIndicator(
                              signalStrength,
                              signalColor,
                              isLocked,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    accessPoint.ssid,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildAnimatedSecurityBadge(isWpa3, isWpa2, isWpa),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_getWiFiStandardName(accessPoint.standard)} • CH ${getWifiChannelInfo(accessPoint.frequency.toDouble())}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.2,
                              ),
                            ),
                            Text(
                              vendorName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Animated Details Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: Opacity(
                            opacity: value,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildAnimatedDetailChip(
                                    Icons.speed_rounded,
                                    '${dBmValue}dBm',
                                    signalColor,
                                  ),
                                  _buildAnimatedDetailChip(
                                    Icons.straighten_rounded,
                                    '≈${distance.toStringAsFixed(1)}m',
                                    Colors.blue[700]!,
                                  ),
                                  _buildAnimatedDetailChip(
                                    Icons.wifi_rounded,
                                    '${accessPoint.frequency}MHz',
                                    Colors.green[700]!,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildAnimatedSignalIndicator(
    String strength, Color color, bool isLocked) {
  return Stack(
    alignment: Alignment.center,
    children: [
      Icon(
        Icons.wifi,
        size: 32,
        color: color,
      ),
      if (isLocked)
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.lock,
              size: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ),
    ],
  );
}

Widget _buildAnimatedSecurityBadge(bool isWpa3, bool isWpa2, bool isWpa) {
  String text = isWpa3
      ? 'WPA3'
      : isWpa2
          ? 'WPA2'
          : isWpa
              ? 'WPA'
              : 'Open';

  Color backgroundColor = isWpa3
      ? Colors.green[100]!
      : isWpa2
          ? Colors.blue[100]!
          : isWpa
              ? Colors.orange[100]!
              : Colors.grey[100]!;

  Color textColor = isWpa3
      ? Colors.green[800]!
      : isWpa2
          ? Colors.blue[800]!
          : isWpa
              ? Colors.orange[800]!
              : Colors.grey[800]!;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    ),
  );
}

Widget _buildAnimatedDetailChip(IconData icon, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    ),
  );
}


  String _getWiFiStandardName(WiFiStandards standard) {
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

  String _getSignalStrengthText(int level) {
    if (level >= -30) return 'Excellent';
    if (level >= -67) return 'Good';
    if (level >= -70) return 'Fair';
    if (level >= -80) return 'Weak';
    if (level >= -90) return 'Poor';
    return 'Very Poor';
  }

  Widget _buildSignalIndicator(String strength, Color color, bool isLocked) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLocked ? Icons.wifi_rounded : Icons.wifi_rounded,
            color: color,
            size: 25,
          ),
        ),
        if (isLocked)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                Icons.lock_rounded,
                color: color,
                size: 10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSecurityBadge(bool isWpa3, bool isWpa2, bool isWpa) {
    if (!isWpa && !isWpa2 && !isWpa3) return const SizedBox.shrink();

    final security = isWpa3 ? 'WPA3' : (isWpa2 ? 'WPA2' : 'WPA');
    final color =
        isWpa3 ? Colors.purple : (isWpa2 ? Colors.blue : Colors.green);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        security,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAccessPointDialog(
      BuildContext context, WiFiAccessPoint accessPoint) {
    final isWpa3 = accessPoint.capabilities.contains("RSN-SAE");
    final isWpa2 = accessPoint.capabilities.contains("WPA2-PSK");
    final isWpa = accessPoint.capabilities.contains("WPA");
    final signalColor = _getColorForSignalStrength(accessPoint.level);
    final distance = calculateDistance(accessPoint.level);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: signalColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.wifi_rounded,
                        color: signalColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            accessPoint.ssid,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getWiFiStandardName(accessPoint.standard),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Signal Strength Gauge
                AspectRatio(
                  aspectRatio: 2,
                  child: _buildGaugeIndicator(
                      context, accessPoint.level.toDouble()),
                ),
                const SizedBox(height: 24),

                // Quick Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickStat(
                      Icons.signal_cellular_alt_rounded,
                      '${accessPoint.level} dBm',
                      signalColor,
                    ),
                    _buildQuickStat(
                      Icons.straighten_rounded,
                      '≈${distance.toStringAsFixed(1)} m',
                      Colors.blue[700]!,
                    ),
                    _buildQuickStat(
                      Icons.router_rounded,
                      '${getWifiChannelInfo(accessPoint.frequency.toDouble())}',
                      Colors.green[700]!,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Detailed Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'BSSID',
                        accessPoint.bssid,
                        Icons.fingerprint_rounded,
                        Colors.purple[700]!,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Frequency',
                        '${accessPoint.frequency} MHz',
                        Icons.speed_rounded,
                        Colors.orange[700]!,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Security',
                        _getSecurityText(isWpa3, isWpa2, isWpa),
                        Icons.security_rounded,
                        Colors.red[700]!,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
               Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    TextButton(
      onPressed: () => Navigator.of(context).pop(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        'Close',
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    const SizedBox(width: 8),
    // ใช้ Expanded เพื่อให้ปุ่มสามารถขยายได้เต็มที่
    Expanded(
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          _createHeatmap(accessPoint);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: signalColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // const Icon(Icons.map_rounded, size: 18),
            const SizedBox(width: 4),
            // ข้อความ 'Create Heatmap' จะแสดงเต็มที่
            Text(
              'Create Heatmap',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    ),
  ],
),

              ],
            ),
          ),
        );
      },
    );
  }



  Widget _buildQuickStat(IconData icon, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getSecurityText(bool isWpa3, bool isWpa2, bool isWpa) {
    if (isWpa3) return 'WPA3 (Enhanced Security)';
    if (isWpa2) return 'WPA2 (Standard Security)';
    if (isWpa) return 'WPA (Basic Security)';
    return 'Open Network (Unsecured)';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black45, // Set the color of the label text
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87, // Set the color of the value text
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeIndicator(BuildContext context, double signalStrength) {
    final screenWidth = MediaQuery.of(context).size.width;
    final radius = screenWidth * 0.25;
    final normalizedValue = signalStrength.abs();

    return AnimatedRadialGauge(
      duration: const Duration(seconds: 1),
      curve: Curves.elasticOut,
      radius: radius,
      value: normalizedValue,
      axis: GaugeAxis(
        min: 0,
        max: 100,
        degrees: 240,
        style: const GaugeAxisStyle(
          thickness: 8,
          background: Color(0xFFDFE2EC),
        ),
        progressBar: GaugeProgressBar.rounded(
          color: _getColorForSignalStrength(signalStrength.toInt()),
        ),
      ),
    );
  }

  Widget _buildTimeGraph() {
    List<LineSeries<ChartData, int>> series = [];

    for (var ap in accessPoints) {
      if (selectedAccessPoints[ap.bssid] == true) {
        var levels = levelsByBSSID[ap.bssid]?[ap.ssid] ?? [];
        List<ChartData> chartData = List.generate(
          levels.length,
          (index) => ChartData(index, levels[index]),
        );

        series.add(LineSeries<ChartData, int>(
          dataSource: chartData,
          xValueMapper: (data, _) => data.x,
          yValueMapper: (data, _) => data.y,
          name: '${ap.bssid} - ${ap.ssid}',
          color: _getUniqueColorForAP(ap.bssid),
        ));
      }
    }

    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.50,
          color: Colors.white,
          child: SfCartesianChart(
            primaryXAxis: NumericAxis(
              minimum: 0,
              maximum: 23,
              interval: 1,
              labelFormat: ' ',
            ),
            primaryYAxis: NumericAxis(
              minimum: -100,
              maximum: 0,
              interval: 10,
            ),
            series: series,
            legend: Legend(isVisible: false),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: accessPoints.length,
            separatorBuilder: (context, index) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
              ),
              child: Divider(height: 1),
            ),
            itemBuilder: (context, index) {
              final ap = accessPoints[index];
              final levels = levelsByBSSID[ap.bssid]?[ap.ssid] ?? [];
              return ListTile(
                leading: Checkbox(
                  value: selectedAccessPoints[ap.bssid] ?? false,
                  onChanged: (bool? value) {
                    setState(() {
                      selectedAccessPoints[ap.bssid] = value ?? false;
                    });
                  },
                  activeColor: _getUniqueColorForAP(ap.bssid),
                ),
                title: Text(ap.ssid),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    23,
                    (i) => Container(
                      width: 2,
                      height: 10,
                      margin: EdgeInsets.symmetric(horizontal: 1),
                      color: i <
                              (levels.isNotEmpty
                                  ? (levels.last.abs() / 6).toInt()
                                  : 0)
                          ? _getColorForSignalStrength(
                              levels.isNotEmpty ? levels.last.toInt() : 0)
                          : Colors.grey[300],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getUniqueColorForAP(String ssid) {
    // นำ hash ของ SSID มาใช้ในการกำหนดสี
    // เพื่อให้แต่ละ AP มีสีที่แตกต่างกันและคงที่
    int hash = ssid.hashCode;
    return Color.fromRGBO(
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
      1.0,
    );
  }

  Widget _buildLoadingScreen() {
    return AnimatedSwitcher(
      duration: const Duration(seconds: 1),
      child: _isLoadingById
          ? Scaffold(
              // Wrap in a Scaffold for fullscreen
              backgroundColor: Colors.white, // Set background color as needed
              body: Center(
                child: Image.asset(
                  'assets/images/loading.gif', // Path to your GIF file
                  width: 200, // Full width of the screen
                  height: 200, // Full height of the screen
                  fit: BoxFit.contain, // Cover the entire screen
                ),
              ),
            )
          : ListView.builder(
              key: const Key('loaded'),
              itemCount: accessPoints.length,
              itemBuilder: (context, index) => _buildWifiTile(index),
            ),
    );
  }

  Widget _buildUserList(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[100],
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 10, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Users',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                      onPressed: () {
                        setState(() {
                          _isGridView = !_isGridView;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    _isLoadingById ? _buildLoadingScreen() : _buildUserView(),
              ),
            ],
          ),
          floatingActionButton: role == 0
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GeneratePage()),
                    );
                  },
                  child: Icon(Icons.person_add),
                  backgroundColor: Colors.white,
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ],
    );
  }

  Widget _buildUserView() {
    return Column(
      children: [
        Expanded(
          child: _isGridView ? _buildUserGrid() : _buildUserListView(),
        ),
        _buildPagination(),
      ],
    );
  }

  Widget _buildUserGrid() {
    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Determine items per page based on screen width
    int itemsPerPage;
    if (screenWidth > 600) {
      itemsPerPage = 12; // For larger screens (e.g., tablets)
    } else {
      itemsPerPage = 8; // For smaller screens (e.g., phones)
    }

    // Calculate startIndex and endIndex dynamically based on itemsPerPage
    int startIndex = _currentPageUsers * itemsPerPage;
    int endIndex = min(startIndex + itemsPerPage, _users.length);
    List<User> currentPageUsers = _users.sublist(startIndex, endIndex);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            screenWidth > 600 ? 4 : 2, // Adjust grid layout dynamically
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: currentPageUsers.length,
      itemBuilder: (context, index) {
        if (userID != currentPageUsers[index].userId) {
          return _buildUserCard(currentPageUsers[index]);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildUserCard(User user) {
    return GestureDetector(
      onTap: () => _showOptionsDialog(context, user.userId, user),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatar(user),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      '${user.firstName} ${user.lastName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (user.role == 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.verified_user,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(User user) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          user.firstName[0].toUpperCase() + user.lastName[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserListTile(User user) {
    return ListTile(
      leading: _buildAvatar(user),
      title: Text('${user.firstName} ${user.lastName}'),
      subtitle: Text(user.email),
      trailing: user.role == 1
          ? Icon(Icons.verified_user, color: Colors.green)
          : null,
      onTap: () => _showOptionsDialog(context, user.userId, user),
    );
  }

  Widget _buildUserListView() {
    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Determine items per page based on screen width
    int itemsPerPage;
    if (screenWidth > 600) {
      itemsPerPage = 12; // For larger screens (e.g., tablets)
    } else {
      itemsPerPage = 8; // For smaller screens (e.g., phones)
    }

    // Calculate startIndex and endIndex dynamically based on itemsPerPage
    int startIndex = _currentPageUsers * itemsPerPage;
    int endIndex = min(startIndex + itemsPerPage, _users.length);
    List<User> currentPageUsers = _users.sublist(startIndex, endIndex);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentPageUsers.length,
      itemBuilder: (context, index) {
        if (userID != currentPageUsers[index].userId) {
          return _buildUserListTile(currentPageUsers[index]);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildPagination() {
    // ดึงขนาดความกว้างของหน้าจอ
    double screenWidth = MediaQuery.of(context).size.width;

    // กำหนดจำนวนรายการต่อหน้า (itemsPerPage) ตามขนาดหน้าจอ
    int itemsPerPage;
    if (screenWidth > 600) {
      itemsPerPage = 12; // สำหรับหน้าจอขนาดใหญ่ (เช่น แท็บเล็ต)
    } else {
      itemsPerPage = 8; // สำหรับหน้าจอขนาดเล็ก (เช่น สมาร์ทโฟน)
    }

    // คำนวณจำนวนหน้าทั้งหมด (totalPages) โดยพิจารณาจากจำนวนรายการต่อหน้า
    int totalPages = (_users.length / itemsPerPage).ceil();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _currentPageUsers > 0
                ? _previousPageUser
                : null, // ถ้าหน้าไม่ใช่หน้าแรกจะเปิดใช้งานปุ่มย้อนกลับ
            child: Text(
              '<<',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _currentPageUsers > 0
                    ? Colors.blue
                    : Colors.grey, // เปลี่ยนสีปุ่มตามสถานะ
              ),
            ),
          ),
          SizedBox(width: 16),
          Text(
              '${_currentPageUsers + 1}/$totalPages'), // แสดงหมายเลขหน้าปัจจุบันและจำนวนหน้าทั้งหมด
          SizedBox(width: 16),
          GestureDetector(
            onTap: _currentPageUsers < totalPages - 1
                ? _nextPageUser
                : null, // ถ้าหน้าไม่ใช่หน้าสุดท้ายจะเปิดใช้งานปุ่มถัดไป
            child: Text(
              '>>',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _currentPageUsers < totalPages - 1
                    ? Colors.blue
                    : Colors.grey, // เปลี่ยนสีปุ่มตามสถานะ
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, int userId, User user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'User Management Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(
                thickness: 2,
                height: 20,
                color: Colors.grey,
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: ListTile(
                  title: Text(
                    'User ID: $userId',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  subtitle: Text(
                    'User Role: ${convertRoleToString(user.role)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Visibility(
                visible: _user?.role != 1, // ซ่อนปุ่มหาก role == 1
                child: _buildOptionButton(
                  icon: Icons.verified_user,
                  text: 'Approve User',
                  onTap: () async {
                    await _approveUser(userId);
                    Navigator.pop(context);
                  },
                ),
              ),
              Visibility(
                visible: _user?.role != 1, // ซ่อนปุ่มหาก role == 1
                child: _buildOptionButton(
                  icon: Icons.block,
                  text: 'Disapprove User',
                  onTap: () async {
                    await _revokeUser(userId);
                    Navigator.pop(context);
                  },
                ),
              ),
              _buildOptionButton(
                icon: Icons.edit,
                text: 'Edit User Information',
                onTap: () {
                  // _navigateToEditInformation(context,user);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditInformationUser(
                        firstName: user.firstName,
                        lastName: user.lastName,
                        description: user.description,
                        image: user.image,
                        userId: userId,
                        email: user.email,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      // print('object');
                      // ทำการรีเฟรชข้อมูลที่นี่หาก result เป็น true
                      _fetchUsersByRole();
                      _loadConnectionDetails();
                    }
                  });
                  // Navigator.pop(context);
                  // // Add code to handle user information editing
                },
              ),
              Visibility(
                visible:
                    _user?.role == 0 || _user?.role == 1, // show if role == 0
                child: _buildOptionButton(
                  icon: Icons.delete,
                  text: 'Delete User',
                  onTap: () async {
                    // Show confirmation dialog
                    bool confirmDelete = await showDialogConfirmation(context);

                    if (confirmDelete == true) {
                      // Proceed with deletion
                      await _deleteUser(userId, 0);
                    }
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

//   Future<void> _navigateToEditInformation(BuildContext context, User user) async {
//   final result = await Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => EditInformationUser(
//         firstName: user.firstName,
//         lastName: user.lastName,
//         description: user.description,
//         image: user.image,
//         userId: userId,
//         email: user.email,
//       ),
//     ),
//   );

//   // ตรวจสอบค่าที่ส่งกลับ
//   if (result == true) {
//    getUserById(); // เรียกใช้ฟังก์ชันที่คุณต้องการเมื่อผลลัพธ์เป็น true
//   }
// }

  Future<bool> showDialogConfirmation(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this user?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels deletion
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                Navigator.of(context).pop(true); // User confirms deletion
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String text,
    required Function onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      onTap: () => onTap(),
    );
  }

  String convertRoleToString(int role) {
    if (role == 0) {
      return 'Root';
    } else if (role == 1) {
      return 'User manager group member';
    } else {
      return 'User';
    }
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    // print(_user?.userId);
    String? token = await _checkSession();
    if (token == null) {
      print('Error: No valid session token');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://${_ipAddress}:${_port}/api/users/${_user?.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);

        setState(() {
          _users = jsonResponse.map((user) => User.fromJson(user)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUsersByRole() async {
    setState(() {
      _isLoadingById = true;
    });

    String? token = await _checkSession();
    if (token == null) {
      print('Error: No valid session token');
      setState(() {
        _isLoadingById = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://${_ipAddress}:${_port}/api/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'userId': _user?.userId, 'role': _user?.role}),
      );

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);

        setState(() {
          _users = jsonResponse.map((user) => User.fromJson(user)).toList();
          _isLoadingById = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        _isLoadingById = false;
      });
    }
  }

  Future<void> getUserById() async {
    String? token = await _checkSession();
    if (token == null) {
      print('Error: No valid session token');
      setState(() {
        _isLoading =
            false; // Set loading state to false since no session token is available
      });
      return;
    }
    // print('xx');
    final url = 'http://${_ipAddress}:${_port}/api/user/${_user?.userId}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');

        // Parse the JSON response
        final List jsonResponse = json.decode(response.body);

        // Assuming the response is a list with one user object
        if (jsonResponse.isNotEmpty) {
          final userJson = jsonResponse[0];

          // Print the description field
          print('Description: ${userJson['description']}');

          setState(() {
            // Create a User object from the JSON
            _isME = User.fromJson(userJson);

            // Set the values from _isME
            Fname = _isME?.firstName ?? '';
            Lname = _isME?.lastName ?? '';
            image = _isME?.image;
            email = _isME?.email ?? '';
            description = _isME?.description ?? '';
            uid = _isME?.userId ?? 0;
          });
        } else {
          print('No user data found in response');
        }
      } else {
        throw Exception('Failed to load user');
      }
    } catch (error) {
      // Handle any errors
      print('Error fetching user: $error');
      throw error;
    }
  }

  Future<void> _approveUser(int userId) async {
    await _updateUserRole(userId, 1);
  }

  Future<void> _revokeUser(int userId) async {
    await _updateUserRole(userId, 2);
  }

  Future<void> _updateUserRole(int userId, int role) async {
    String? token = await _checkSession();
    if (token == null) {
      print('Error: No valid session token');
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('http://${_ipAddress}:${_port}/api/users/$userId/role'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        print('User role updated successfully');
        await _fetchUsers(); // Refresh the user list
      } else {
        print('Failed to update user role: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error updating user role: $e');
    }
  }

  Future<void> _deleteUser(int userId, int role) async {
    String? token = await _checkSession();
    if (token == null) {
      print('Error: No valid session token');
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('http://${_ipAddress}:${_port}/api/users/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        print('User deleted successfully');

        await _fetchUsersByRole(); // Refresh the user list
      } else {
        print('Failed to delete user: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  Widget _buildBottomNavigationBar() {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.wifi),
        label: 'Access Points',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.access_time),
        label: 'Time',
      ),
    ];
    // print('print islogin on line 932 ${_isLoggedIn}');
    if (_isLoggedIn == true) {
      if (_user?.role == 0 || _user?.role == 1) {
        // print('print user role on line 932 ${_user?.firstName}');
        items.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.supervised_user_circle_outlined),
            label: 'User List',
          ),
        );
      }
    }

    return BottomNavigationBar(
      backgroundColor: Colors.white,
      items: items,
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 0) {
          _startScanning();
        } else if (index == 2 && (_user?.role == 0 || _user?.role == 1)) {
          print('user ID at linr 996 ${_user?.userId}');
          _fetchUsersByRole();
        } else {
          _stopScanning();
        }
      },
    );
  }

  Color _getColorForSignalStrength(int level) {
    if (level >= -30) return Colors.green;
    if (level >= -67) return Colors.lightGreen;
    if (level >= -70) return Colors.yellow;
    if (level >= -80) return Colors.orange;
    if (level >= -90) return Colors.deepOrange;
    return Colors.grey;
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

  void _createHeatmap(WiFiAccessPoint selectedAccessPoint) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    if (!_isLoggedIn) {
      try {
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      } catch (e) {
        // print('Error picking image: $e');
      }

      if (pickedFile != null) {
        String imagePath = pickedFile.path;
        _showLocationNameBottomSheet(context, selectedAccessPoint, imagePath);
      } else {
        String imagePath =
            'assets/images/map3.png'; // Default image path if no image selected
        _showLocationNameBottomSheet(context, selectedAccessPoint, imagePath);
      }
    }
    // else {
    //   // print('User is not logged in');
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => CreateHeatmap(
    //         accessPoint: selectedAccessPoint,
    //         updateSignalStrength: updateSignalStrength,
    //         imagePath: 'assets/images/map3.png',
    //         location: 'demo location',
    //         name: 'Wi-Fi Survey',
    //         mapID: MapID,
    //       ),
    //     ),
    //   );
    // }
  }

  void _showLocationNameBottomSheet(BuildContext context,
      WiFiAccessPoint selectedAccessPoint, String imagePath) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      'Create New Heatmap',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Project Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.create),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a project name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState != null &&
                              _formKey.currentState!.validate()) {
                            // print(imagePath);
                            String name = nameController.text;
                            String location = locationController.text;

                            _navigateToCreateHeatmap(context,
                                selectedAccessPoint, imagePath, name, location);
                          }
                        },
                        icon: const Icon(Icons.map),
                        label: const Text('Create Heatmap'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Theme.of(context).canvasColor,
                          disabledBackgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    // print(base64Image);
    return base64Image;
  }

  Future<void> _navigateToCreateHeatmap(
    BuildContext context,
    WiFiAccessPoint selectedAccessPoint,
    String? imagePath, // รับ String? เพื่อรองรับค่า null
    String name,
    String location,
  ) async {
    if (imagePath == null) {
      print('Error: imagePath is null');
      return;
    }
    setState(() {
      MapID++;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateHeatmap(
          accessPoint: selectedAccessPoint,
          updateSignalStrength: updateSignalStrength,
          imagePath: imagePath,
          location: location,
          name: name,
          mapID: MapID,
        ),
      ),
    );
  }

  // Future<void> _navigateToCreateHeatmap(
  //   BuildContext context,
  //   WiFiAccessPoint selectedAccessPoint,
  //   String? imagePath,
  //   String name,
  //   String location,
  // ) async {
  //   try {
  //     // ตรวจสอบ session token
  //     String? token = await _checkSession();
  //     if (token == null) {
  //       print('ข้อผิดพลาด: ไม่มี session token ที่ถูกต้อง');
  //       return;
  //     }

  //     // ตรวจสอบว่าผู้ใช้เข้าสู่ระบบแล้ว
  //     if (_user?.userId == null) {
  //       print('ข้อผิดพลาด: ผู้ใช้ไม่ได้เข้าสู่ระบบหรือ User ID เป็น null');
  //       return;
  //     }

  //     int id = _user!.userId!;
  //     String? base64Image;

  //     // แปลงรูปภาพเป็น base64
  //     if (imagePath != null) {
  //       try {
  //         base64Image = await convertImageToBase64(imagePath);
  //       } catch (e) {
  //         print('ข้อผิดพลาดในการแปลงรูปภาพ: $e');
  //         return;
  //       }
  //     } else {
  //       print('ข้อผิดพลาด: imagePath เป็น null');
  //       return;
  //     }

  //     // ส่งคำขอ POST เพื่อสร้างแผนที่
  //     final response = await http.post(
  //       Uri.parse('http://${_ipAddress}:${_port}/api/maps'),
  //       headers: <String, String>{
  //         'Content-Type': 'application/json; charset=UTF-8',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: jsonEncode(<String, dynamic>{
  //         'User_id': id,
  //         'name': name,
  //         'BSSID': selectedAccessPoint.bssid,
  //         'SSID': selectedAccessPoint.ssid,
  //         'frequency': selectedAccessPoint.frequency,
  //         'location': location,
  //         'image_data': base64Image,
  //         'Created_at': DateTime.now().toIso8601String(),
  //       }),
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       print('สร้างแผนที่สำเร็จ');
  //       // แปลง JSON string เป็น Map
  //       final responseBody = jsonDecode(response.body);

  //       // ดึงค่า mapId จาก Map
  //       final mapId = responseBody['mapId'];
  //       // print('Map ID: $mapId');
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => CreateHeatmap(
  //             accessPoint: selectedAccessPoint,
  //             updateSignalStrength: updateSignalStrength,
  //             imagePath: imagePath,
  //             location: location,
  //             name: name,
  //             mapID: mapId,
  //           ),
  //         ),
  //       );
  //     } else {
  //       print('ไม่สามารถสร้างแผนที่ได้ รหัสสถานะ: ${response.statusCode}');
  //     }
  //   } catch (e, stackTrace) {
  //     print('เกิดข้อผิดพลาด: $e');
  //     print('Stack trace: $stackTrace');
  //     // จัดการข้อผิดพลาดตามที่เหมาะสม
  //   }
  // }
}

class ChartData {
  ChartData(this.x, this.y);
  final int x;
  final double y;
}

class MemoizedProfileImage extends StatefulWidget {
  final String? imageData;

  const MemoizedProfileImage({Key? key, this.imageData}) : super(key: key);

  @override
  _MemoizedProfileImageState createState() => _MemoizedProfileImageState();
}

class _MemoizedProfileImageState extends State<MemoizedProfileImage> {
  late ImageProvider _imageProvider;

  @override
  void initState() {
    super.initState();
    _imageProvider = _getImageProvider(widget.imageData);
  }

  @override
  void didUpdateWidget(covariant MemoizedProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageData != oldWidget.imageData) {
      setState(() {
        _imageProvider = _getImageProvider(widget.imageData);
      });
    }
  }

  ImageProvider _getImageProvider(String? imageData) {
    if (imageData != null) {
      return MemoryImage(base64Decode(imageData));
    } else {
      return AssetImage('assets/images/person1.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.orange,
      backgroundImage: _imageProvider,
    );
  }
}

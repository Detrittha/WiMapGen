import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wimapgen/model/map_model.dart';
import 'package:wimapgen/model/mapversion.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import 'package:wimapgen/config/hostname.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:wimapgen/menu/create_heatmap.dart';
import 'package:wimapgen/menu/continueHeatmap.dart';


class VersionHeatmapPage extends StatefulWidget {
  final int mapId;

  VersionHeatmapPage({required this.mapId});
  @override
  _VersionHeatmapPageState createState() => _VersionHeatmapPageState();
}

class _VersionHeatmapPageState extends State<VersionHeatmapPage> {
  List<Project> versions = [];
  bool isLoading = true;
    String _ipAddress = '';
  int _port = 0;
  List<Project> projects = [];
  @override
  void initState() {
    super.initState();
    _loadSavedVersions();
    //  _loadConnectionDetails();
    // fetchVersionProjects();
   
    // requestStoragePermission();
  }

  
Future<void> _loadSavedVersions() async {
  setState(() {
    isLoading = false; // Ensure your loading indicator variable matches your convention
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final versionsList = prefs.getStringList('saved_versions') ?? [];

    setState(() {
      // Convert JSON strings to Project objects
      projects = versionsList.map((String version) {
        Map<String, dynamic> versionMap = jsonDecode(version);

        return Project(
          mapId: versionMap['Map_id'] ?? 0, // Ensure correct type (int)
          userId: versionMap['User_id'] ?? 0, // Ensure correct type (int)
          versionId: versionMap['Version_id'] ?? 0,
          name: versionMap['name'] ?? '',
          bssid: versionMap['BSSID'] ?? '',
          ssid: versionMap['SSID'] ?? '',
          frequency: versionMap['frequency'] ?? '',
          location: versionMap['location'] ?? '',
          imageData: versionMap['ImageData'] ?? '',
          description: versionMap['description'] ?? '',
          maxDbm: versionMap['Max_dBm']?.toString() ?? '',
          minDbm: versionMap['Min_dBm']?.toString() ?? '',
          image: versionMap['Image'] ?? '',
          createdAt: versionMap['Created_at'] != null
              ? DateTime.parse(versionMap['Created_at'])
              : DateTime.now(),
        );
      }).toList();
    });

    // Debug log
    print('=== Loaded Projects ===');
    print('Total projects: ${projects.length}');
    for (var project in projects) {
      print('\nMap ID: ${project.mapId}');
      print('Name: ${project.name}');
      print('Created at: ${project.createdAt}');
      print('Max dBm: ${project.maxDbm}');
      print('Min dBm: ${project.minDbm}');
      print('image: ${project.image}');
    }
  } catch (e) {
    print('Error loading versions: $e');
  } finally {
    setState(() {
      isLoading = false; // Ensure loading indicator stops in all cases
    });
  }
}

  // Future<void> _loadConnectionDetails() async {
    
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // setState(() {

  //   _ipAddress = prefs.getString('ip_address') ?? '192.168.136.20';
  //   _port = prefs.getInt('port') ?? 3000;
    
    
  // });}

  // Future<String?> _getToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getString('auth_token');
  // }

  // Future<void> fetchVersionProjects() async {
  //   // log('Fetching versions...');
  //   setState(() => isLoading = true);
  //   try {
  //     String? token = await _getToken();
  //     if (token == null) {
  //       throw Exception('No token found. Please login.');
  //     }

  //     final response = await http.post(
  //       Uri.parse('http://${_ipAddress}:${_port}/api/versions'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //       body: jsonEncode({
  //         'mapId': widget
  //             .mapId, // Example mapId; adjust as necessary or make dynamic
  //       }),
  //     );

  //     // log('Response status code: ${response.statusCode}');
  //     // log('Response body: ${response.body}');

  //     if (response.statusCode == 200) {
  //       print(response.body);
  //       if (response.body.isNotEmpty) {
  //         List<dynamic> jsonVersions = jsonDecode(response.body);
  //         setState(() {
  //           versions =
  //               jsonVersions.map((json) => Heatmap.fromJson(json)).toList();
  //           isLoading = false;
  //         });
  //         // log('Versions fetched successfully. Count: ${versions.length}');
  //       } else {
  //         throw Exception('Empty response body');
  //       }
  //     } else if (response.statusCode == 403) {
  //       throw Exception('Authentication failed. Please login again.');
  //     } else {
  //       throw Exception(
  //           'Failed to load versions. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     // log('Error fetching versions: $e');
  //     setState(() => isLoading = false);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: ${e.toString()}')),
  //     );
  //   }
  // }
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false, // Prevent default back button behavior
    onPopInvoked: (didPop) {
      if (didPop) return;
      // Handle back button press
      Navigator.of(context).pop(true);
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text('Version Heatmap'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Send result = true back when pressing back button in AppBar
            Navigator.of(context).pop(true);
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? Center(
                child: Image.asset(
                  'assets/images/loading.gif',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              )
            : _buildVersionList(),
      ),
    ),
  );
}


//   Future<void> _getStoragePermission() async {
//     DeviceInfoPlugin plugin = DeviceInfoPlugin();
//     AndroidDeviceInfo android = await plugin.androidInfo;
//        if (android.version.sdkInt < 33) {
//           if (await Permission.storage.request().isGranted) {
//              setState(() {
//                permissionGranted = true;
//              });
//           } else if (await Permission.storage.request().isPermanentlyDenied) {
//              await openAppSettings();
//           } else if (await Permission.audio.request().isDenied) {
//              setState(() {
//                permissionGranted = false;
//              });
//           }
//         } else {
//            if (await Permission.photos.request().isGranted) {
//                 setState(() {
//                    permissionGranted = true;
//                 });
//            } else if (await Permission.photos.request().isPermanentlyDenied) {
//                await openAppSettings();
//            } else if (await Permission.photos.request().isDenied) {
//                setState(() {
//                    permissionGranted = false;
//                });
//          }
//       }
// }

  Future<void> requestStoragePermission(Project version) async {
    try {
      if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          // For Android 13 and above
          Map<Permission, PermissionStatus> statuses = await [
            Permission.photos,
            // Permission.videos,
            // Permission.audio,
          ].request();

          if (statuses.values
              .any((status) => status.isDenied || status.isPermanentlyDenied)) {
            throw "Please allow media permissions to access files";
          }
        } else {
          // For Android 12 and below
          final status = await Permission.storage.request();
          if (status.isDenied || status.isPermanentlyDenied) {
            throw "Please allow storage permission to access files";
          }
        }
      }

      // If we've reached here, permissions are granted
      await fetchAndSaveImage(version);
    } catch (e) {
      print("Error in requestStoragePermission: $e");
      rethrow; // Re-throw the error for the caller to handle
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      return sdkInt >= 33; // Android 13 is API level 33
    }
    return false;
  }

  Widget _buildVersionList() {
  // กรองรายการ projects โดยแสดงเฉพาะ mapId ที่ตรงกับ widget.mapId
  final filteredProjects = projects.where((project) => project.mapId == widget.mapId).toList();

  return ListView.builder(
    itemCount: filteredProjects.length,
    itemBuilder: (context, index) {
      return _buildVersionCard(context, filteredProjects[index], index);
    },
  );
}


  Widget _buildVersionCard(BuildContext context, Project version, int index) {
    return GestureDetector(
      onTap: () {
        _showOptionsDialog(context, version,versions);
      },
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildVersionImage(version.image),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        version.name,
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      // IconButton(
                      //   icon: Icon(Icons.edit, color: Colors.grey),
                      //   onPressed: () {
                      //     // _editProjectName(context, project);
                      //   },
                      // ),
                    ],
                  ),
                  _buildInfoRow(Icons.access_time,
                      'Created: ${_formatDate(version.createdAt.toString())}'),
                  _buildInfoRow(Icons.location_on,
                      'Location: ${version.location}'),
                  _buildInfoRow(
                    Icons.info_outline,
                    'Version: ${index + 1}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionImage(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return _buildErrorImage();
    }
    try {
      return Image.memory(
        base64Decode(imageData),
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          log('Error loading image: $error');
          return _buildErrorImage();
        },
      );
    } catch (e) {
      log('Failed to decode image: $e');
      return _buildErrorImage();
    }
  }

  Widget _buildErrorImage() {
    return Container(
      height: 180,
      color: Colors.grey[300],
      child: Icon(Icons.error, color: Colors.red),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    String formattedTime = DateFormat('h:mm a').format(date);
    return '${date.day}/${date.month}/${date.year}  $formattedTime';
  }
void _showOptionsDialog(BuildContext context, Project version, List<Project> allVersions) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Version Options',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildOptionButton(
              icon: Icons.map,
              text: 'View Heatmap',
              onTap: () {
                Navigator.pop(context);
                _showHeatmapDialog(context, version);
              },
            ),
            _buildOptionButton(
              icon: Icons.edit_location,
              text: 'Continue',
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (context) => ContinueHeatmapPage(
                      name: version.name,
                      location: version.location,
                      bssid: version.bssid,
                      image: version.image,
                      mapId: widget.mapId,
                      ssid: version.ssid,
                      frequency: version.frequency,
                      imagePath: version.imageData,
                    ),
                  ),
                )
                    .then((result) {
                  if (result == true) {
                    Navigator.pop(context, true);
                   _loadSavedVersions();
                  }
                });
              },
            ),
              _buildOptionButton(
                icon: Icons.delete,
                text: 'Delete Version',
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, version);
                },
              )
          ],
        ),
      );
    },
  );
}


  Widget _buildOptionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(text),
      onTap: onTap,
    );
  }

  void _showHeatmapDialog(BuildContext context, Project version) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _buildDialogContent(context, version),
        );
      },
    );
  }

  Widget _buildDialogContent(BuildContext context, Project version) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
        children: <Widget>[
          _buildHeader(version),
          SizedBox(height: 16),
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                child: _buildDetails(version),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  // เรียกใช้ฟังก์ชันบันทึกข้อมูลที่นี่
                  await requestStoragePermission(version);
                  // แสดงข้อความยืนยันการบันทึกได้ที่นี่
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved Successfully')),
                  );
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Save image',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.blue, // เปลี่ยนสีตามต้องการ
                  ),
                ),
              ),
              SizedBox(width: 10), // เพิ่มระยะห่างระหว่างปุ่ม
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey, // เปลี่ยนสีตามต้องการ
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> fetchAndSaveImage(Project version) async {
    //  var status = await Permission.manageExternalStorage.request();
    //  if (status.isGranted) {
    //    try {
    print('permission true');
    // แปลง Base64 เป็น Uint8List
    Uint8List bytes = base64Decode(version.image);

    // บันทึกไฟล์ลงใน Gallery
    final result = await ImageGallerySaver.saveImage(
      bytes,
      quality: 100,
      name: "${version.mapId}_${version.createdAt}.png",
    );

    if (result['isSuccess']) {
      print('Image saved to Gallery: ${result['filePath']}');
    } else {
      print('Failed to save image to Gallery');
    }
    // } catch (e) {
    //   print('Error saving image: $e');
    // }
    // } else {
    //   print('Storage permission denied');
    // }
  }

  Widget _buildHeader(Project version) {
    return Column(
      children: [
        Text(
          'Heatmap Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildVersionImage(version.image),
        ),
      ],
    );
  }

  Widget _buildDetails(Project version) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildDetailSection('Map Information', [
          _buildDetailRow('Version Name', version.name),
          _buildDetailRow('SSID', version.ssid),
          _buildDetailRow('BSSID', version.bssid),
          _buildDetailRow('frequency', '${version.frequency} MHz'),
          // _buildDetailRow(
          //     'Channel', getWifiChannelInfo(version.frequency.toDouble())),
        ]),
        SizedBox(height: 8),
        _buildDetailSection('Signal Strength', [
          _buildDetailRow('Max dBm', version.maxDbm.toString()),
          _buildDetailRow('Min dBm', version.minDbm.toString()),
        ]),
        SizedBox(height: 8),
        _buildDetailSection('Additional Info', [
          _buildDetailRow('Created At', '${version.createdAt.toLocal()}'),
          // _buildDetailRow(
          //     'User', '${version.userFirstName} ${version.userLastName}'),
        ]),
        SizedBox(height: 8),
        // _buildDescriptionSection(version.versionDescription),
      ],
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return ElevatedButton(
      child: Text('Close'),
      onPressed: () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Project version) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this version?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteVersion(version);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
Future<void> _deleteVersion(Project project) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Retrieve saved versions list
    List<String> savedVersions = prefs.getStringList('saved_versions') ?? [];
    
    // Find the project to delete
    savedVersions.removeWhere((versionJson) {
      final Map<String, dynamic> versionMap = jsonDecode(versionJson);
      // Match the project by Map_id or other unique field
      return versionMap['Version_id'] == project.versionId;
    });

    // Save the updated list back to SharedPreferences
    await prefs.setStringList('saved_versions', savedVersions);
     _loadSavedVersions();
    // You may want to refresh the displayed list here (if needed)
  } catch (e) {
    print('Error deleting project: $e');
  }
}


  // void _deleteVersion(Heatmap version) async {
  //   // String? token = await _getToken();

  //   if (token == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('No token found. Please login.')),
  //     );
  //     return;
  //   }

  //   final response = await http.delete(
  //     Uri.parse('http://${_ipAddress}:${_port}/api/version/${version.versionId}'),
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //     },
  //   );

  //   if (response.statusCode == 200) {
      
  //     // Successfully deleted the version
  //     setState(() {
  //       versions.remove(version);
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text('Version deleted successfully'),
  //     ));
  //   } else {
  //     // Failed to delete the version
  //     print('Error response status code: ${response.statusCode}');
  //     print('Error response body: ${response.body}');
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text('Failed to delete the version'),
  //     ));
  //   }
  // }
}

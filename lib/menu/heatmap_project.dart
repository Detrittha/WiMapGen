import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wimapgen/model/map_model.dart';
import 'package:wimapgen/config/hostname.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:wimapgen/menu/version_Heatmap.dart';

String _formatDate(String dateString) {
  DateTime date = DateTime.parse(dateString);
  String formattedTime = DateFormat('h:mm a').format(date); // Format with AM/PM
  return '${date.day}/${date.month}/${date.year}  $formattedTime';
}

class HeatmapProjectPage extends StatefulWidget {
  @override
  _HeatmapProjectPageState createState() => _HeatmapProjectPageState();
}

class _HeatmapProjectPageState extends State<HeatmapProjectPage> {
  List<Project> projects = [];
  List<Map<String, dynamic>> savedVersions = [];
  bool isLoading = true;
  late TextEditingController _controller;
  String _ipAddress = '';
  int _port = 0;
  @override
  void initState() {
    super.initState();
    _loadSavedVersions();
    // _loadConnectionDetails();
    // fetchProjects();
  }

Future<void> _loadSavedVersions() async {
  setState(() {
    isLoading = true;
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final versionsList = prefs.getStringList('saved_versions') ?? [];

    // แปลงข้อมูลเป็น Project objects ก่อน
    final allProjects = versionsList.map((String version) {
      Map<String, dynamic> versionMap = jsonDecode(version);
      
      return Project(
        mapId: versionMap['Map_id'] ?? 0,
        userId: versionMap['User_id'] ?? 0,
        name: versionMap['name'] ?? '',
        versionId: versionMap['Version_id'] ?? 0,
        bssid: versionMap['BSSID'] ?? '',
        ssid: versionMap['SSID'] ?? '',
        frequency: versionMap['frequency'] ?? 0,
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

    // กรองเอาเฉพาะ Map_ID ที่ไม่ซ้ำกัน
    final uniqueProjects = allProjects.fold<Map<int, Project>>({}, (map, project) {
      if (!map.containsKey(project.mapId)) {
        map[project.mapId] = project;
      }
      return map;
    }).values.toList();

    setState(() {
      projects = uniqueProjects;
    });

    // Debug log
    print('=== Loaded Projects ===');
    print('Total projects after filtering: ${projects.length}');
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
      isLoading = false;
    });
  }
}

  //   Future<void> _loadConnectionDetails() async {

  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // setState(() {

  //   _ipAddress = prefs.getString('ip_address') ?? '192.168.136.20';
  //   _port = prefs.getInt('port') ?? 3000;

  // });}

  // Future<String?> _getToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getString('auth_token');
  // }

  // Future<void> fetchProjects() async {
  //   // log('Fetching projects...');
  //   setState(() => isLoading = true);
  //   try {
  //     String? token = await _getToken();
  //     if (token == null) {
  //       throw Exception('No token found. Please login.');
  //     }

  //     final response = await http.get(
  //       Uri.parse('http://${_ipAddress}:${_port}/api/maps'),
  //       headers: {'Authorization': 'Bearer $token'},
  //     );

  //     if (response.statusCode == 200) {
  //       List<dynamic> jsonProjects = jsonDecode(response.body);
  //       setState(() {
  //         projects =
  //             jsonProjects.map((json) => Project.fromJson(json)).toList();
  //         isLoading = false;
  //       });
  //       // log('Projects fetched successfully. Count: ${projects.length}');
  //     } else if (response.statusCode == 403) {
  //       throw Exception('Authentication failed. Please login again.');
  //     } else {
  //       throw Exception(
  //           'Failed to load projects. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     log('Error fetching projects: $e');
  //     setState(() => isLoading = false);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(e.toString())),
  //     );
  //     if (e.toString().contains('Authentication failed')) {
  //       // Navigate to login page
  //       // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Projects'),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(
              child: Image.asset(
                  'assets/images/loading.gif', // Path to your GIF file
                  width: 200, // Full width of the screen
                  height: 200, // Full height of the screen
                  fit: BoxFit.contain // Adjust height as needed
                  ),
            )
          : _buildProjectList(),
    );
  }

Widget _buildProjectList() {
  return ListView.builder(
    itemCount: projects.length,
    itemBuilder: (context, index) {
      // ตรวจสอบว่ามีข้อมูลใน projects[index] หรือไม่
      print(projects[index].name);  // หรือพิมพ์ค่าของฟิลด์ที่คุณต้องการแสดง
      return _buildProjectCard(context, projects[index]);
    },
  );
}


  Widget _buildProjectCard(BuildContext context, Project project) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: () => _showOptionsDialog(context, project),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildProjectImage(project.imageData),
            ),
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
                      project.name,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.grey),
                      onPressed: () {
                        _editProjectName(context, project);
                         
                      },
                    ),
                  ],
                ),
                _buildInfoRow(Icons.access_time,
                    'Created: ${_formatDate(project.createdAt.toString())}'),
                _buildInfoRow(Icons.network_wifi, 'SSID: ${project.ssid}'),
                _buildInfoRow(
                    Icons.location_on, 'Location: ${project.location}'),
                    //  _buildInfoRow(
                    // Icons.account_tree_rounded, 'Map ID: ${project.mapId}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editProjectName(BuildContext context, Project project) {
    final TextEditingController _controller =
        TextEditingController(text: project.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AnimatedPadding(
              padding: MediaQuery.of(context).viewInsets,
              duration: const Duration(milliseconds: 100),
              curve: Curves.decelerate,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Edit Project Name',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _controller.text.isEmpty
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        style: TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'Enter new project name',
                          prefixIcon: Icon(Icons.edit_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Current name: ${project.name}',
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            child: Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              disabledBackgroundColor: Colors.black87,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            child: Text('Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellowAccent,
                              disabledBackgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _controller.text.isNotEmpty &&
                                    _controller.text != project.name
                                ? () {
                                    _updateProjectNameAPI(_controller.text, project);
                                    Navigator.of(context).pop();
                                  }
                                : null,
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
      },
    );
  }


Future<String?> getProjectName(String mapId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // ดึงข้อมูล versions ทั้งหมด
    List<String> savedVersions = prefs.getStringList('saved_versions') ?? [];
    
    // วนลูปหา version ที่มี Map_id ตรงกับที่ต้องการ
    for (String versionString in savedVersions) {
      Map<String, dynamic> versionData = jsonDecode(versionString);
      
      if (versionData['Map_id'] == mapId) {
        return versionData['name'] as String?;
      }
    }
    
    return null; // ถ้าไม่พบข้อมูล
  } catch (e) {
    print('Error getting project name: $e');
    return null;
  }
}

// ตัวอย่างการใช้งาน
Future<void> _updateProjectNameAPI(String newName, Project project) async {
  try {
    // ดึงชื่อเก่า
    String? oldName = await getProjectName(project.mapId.toString());
    
    if (oldName != null) {
      print('Old project name: $oldName');
    } else {
      print('No old project name found for mapId: ${project.mapId}');
    }
    
    // อัพเดทชื่อใหม่ในข้อมูล versions
    final prefs = await SharedPreferences.getInstance();
    List<String> savedVersions = prefs.getStringList('saved_versions') ?? [];
    
    List<String> updatedVersions = savedVersions.map((versionString) {
      Map<String, dynamic> versionData = jsonDecode(versionString);
      
      if (versionData['Map_id'] == project.mapId) {
        versionData['name'] = newName;
        return jsonEncode(versionData);
      }
      return versionString;
    }).toList();
    
    // บันทึกข้อมูลที่อัพเดทแล้ว
    await prefs.setStringList('saved_versions', updatedVersions);
    print('New project name: $newName');
    
    _loadSavedVersions();
  } catch (e) {
    print('Error updating project name: $e');
    rethrow;
  }
}



  // Future<void> _updateProjectNameAPI(String newName, Project project) async {
  //   final url = Uri.parse('http://${_ipAddress}:${_port}/api/maps/${project.mapId}');

  //   try {
  //     final response = await http.put(
  //       url,
  //       headers: <String, String>{
  //         'Content-Type': 'application/json; charset=UTF-8',
  //       },
  //       body: jsonEncode(<String, String>{
  //         'name': newName,
  //       }),
  //     );

  //     if (response.statusCode == 200) {
  //       // If the server returns a 200 OK response, update the local state
  //       setState(() {
  //         fetchProjects();
  //       });
  //     } else {
  //       throw Exception('Failed to update project name');
  //     }
  //   } catch (e) {
  //     print('Error updating project name: $e');
  //   }
  // }

  Widget _buildProjectImage(String image) {
    try {
      return Image.memory(
        base64Decode(image),
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
    String formattedTime =
        DateFormat('h:mm a').format(date); // Format with AM/PM
    return '${date.day}/${date.month}/${date.year}  $formattedTime';
  }

  void _showOptionsDialog(BuildContext context, Project project) {
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
                'Map Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildOptionButton(
                icon: Icons.map,
                text: 'View Map',
                onTap: () {
                  Navigator.pop(context);

                  // Show dialog to display the map image
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Map Image'),
                        content: Container(
                          width: double.maxFinite,
                          child: Image.memory(
                            base64Decode(project.imageData),
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              log('Error loading image: $error');
                              return _buildErrorImage();
                            },
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Close'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
  _buildOptionButton(
  icon: Icons.edit,
  text: 'Edit Project',
  onTap: () async {
    // ปิด option menu ก่อน
    Navigator.of(context).pop();
    
    // จากนั้นค่อย navigate ไปหน้าใหม่
    final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => VersionHeatmapPage(mapId: project.mapId),
    ));
    
    if (result == true) {
      setState(() {
        // อัพเดทข้อมูลที่ต้องการ
      });
      
      // แสดงข้อความแจ้งเตือนถ้าต้องการ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  },
),
              _buildOptionButton(
                icon: Icons.delete,
                text: 'Delete',
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, project);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(text),
      onTap: onTap,
    );
  }
void _showDeleteConfirmation(BuildContext context, Project project) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete the project "${project.name}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog

              // Perform the deletion
              await _deleteProject(project);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Project deleted successfully')),
              );
            },
            child: Text('Delete'),
          ),
        ],
      );
    },
  );
}

Future<void> _deleteProject(Project project) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Retrieve saved versions list
    List<String> savedVersions = prefs.getStringList('saved_versions') ?? [];
    
    // Find the project to delete
    savedVersions.removeWhere((versionJson) {
      final Map<String, dynamic> versionMap = jsonDecode(versionJson);
      // Match the project by Map_id or other unique field
      return versionMap['Map_id'] == project.mapId;
    });

    // Save the updated list back to SharedPreferences
    await prefs.setStringList('saved_versions', savedVersions);
     _loadSavedVersions();
    // You may want to refresh the displayed list here (if needed)
  } catch (e) {
    print('Error deleting project: $e');
  }
}


  // void _deleteProject(Project project) async {
  //   String? token = await _getToken();
  //   final response = await http.delete(
  //     Uri.parse('http://${_ipAddress}:${_port}/api/maps/${project.mapId}'),
  //     headers: {
  //       'Authorization': 'Bearer ${token}',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     // Project deleted successfully
  //     setState(() {
  //       projects.remove(project);
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text('Project deleted successfully'),
  //     ));
  //   } else {
  //     // Failed to delete the project
  //     print('MapID :${project.mapId}');
  //     print('token :${token}}');
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text('Failed to delete the project'),
  //     ));
  //   }
  // }
}

import 'package:flutter/material.dart';
import '../models/family_member.dart';
import '../painters/family_tree_painter.dart';
import 'family_tree_node.dart';
import 'dart:math' show max;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class FamilyTreeView extends StatefulWidget {
  const FamilyTreeView({super.key});

  @override
  _FamilyTreeViewState createState() => _FamilyTreeViewState();
}

class _FamilyTreeViewState extends State<FamilyTreeView> {
  final TransformationController _transformationController = TransformationController();
  List<FamilyMember> members = [];
  Map<String, Offset> nodePositions = {};
  final double nodeWidth = 120.0;
  final double nodeHeight = 60.0;
  List<List<FamilyMember>> _history = [];
List<Map<String, Offset>> _positionHistory = [];
int _currentIndex = -1;

  void _saveState() {
    // Xóa lịch sử sau vị trí hiện tại nếu có thay đổi
    if (_currentIndex < _history.length - 1) {
      _history = _history.sublist(0, _currentIndex + 1);
      _positionHistory = _positionHistory.sublist(0, _currentIndex + 1);
    }
    _history.add(members.map((m) => m.clone()).toList());
    _positionHistory.add(Map.from(nodePositions));
    _currentIndex++;
  }

void undo() {
  if (_currentIndex > 0) {
    setState(() {
      _currentIndex--;
      members = _history[_currentIndex].map((m) => m.clone()).toList();
      nodePositions = Map.from(_positionHistory[_currentIndex]);
    });
  }
}

void redo() {
  if (_currentIndex < _history.length - 1) {
    setState(() {
      _currentIndex++;
      members = _history[_currentIndex].map((m) => m.clone()).toList();
      nodePositions = Map.from(_positionHistory[_currentIndex]);
    });
  }
}

  void addMember(String? parentId) {
    final newMember = FamilyMember(
      id: DateTime.now().toString(),
      name: 'New Member',
      parentId: parentId,
      generation: parentId != null 
          ? members.firstWhere((m) => m.id == parentId).generation + 1 
          : 0,
    );
    setState(() {
      members.add(newMember);
      if (parentId != null) {
        final parent = members.firstWhere((m) => m.id == parentId);
        parent.childrenIds.add(newMember.id);
      }
      _arrangeNodes();
      _saveState();
        // Zoom to the newly added member
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zoomToMember(newMember);
    });
    });
  }
  void _deleteAllMembers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete All Members'),
        content: Text('Are you sure you want to delete all members? This action cannot be undone.'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Delete All'),
            onPressed: () {
              setState(() {
                members.clear();
                nodePositions.clear();
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
  void _showMemberDialog(FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Member Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: member.name,
                decoration: InputDecoration(labelText: 'Name'),
                onChanged: (value) {
                  setState(() {
                    member.name = value;
                  });
                },
              ),
              TextFormField(
                initialValue: member.description,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    member.description = value.isEmpty ? null : value;
                  });
                },
              ),
              TextFormField(
                initialValue: member.imageUrl,
                decoration: InputDecoration(labelText: 'Image URL'),
                onChanged: (value) {
                  setState(() {
                    member.imageUrl = value.isEmpty ? null : value;
                  });
                },
              ),
              ListTile(
                title: Text('Date of Birth'),
                subtitle: Text(member.dateOfBirth?.toString() ?? 'Not set'),
                trailing: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: member.dateOfBirth ?? DateTime.now(),
                      firstDate: DateTime(1800),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        member.dateOfBirth = date;
                      });
                    }
                  },
                ),
              ),
              ListTile(
                title: Text('Date of Death'),
                subtitle: Text(member.dateOfDeath?.toString() ?? 'Not set'),
                trailing: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: member.dateOfDeath ?? DateTime.now(),
                      firstDate: DateTime(1800),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        member.dateOfDeath = date;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Clear Info'),
            onPressed: () {
              setState(() {
                member.name = "deleted";
                member.description = null;
                member.imageUrl = null;
                member.dateOfBirth = null;
                member.dateOfDeath = null;
              });
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Delete Member'),
            onPressed: () {
              _deleteMember(member);
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _deleteMember(FamilyMember member) {
    setState(() {
      if (member.parentId != null) {
        final parent = members.firstWhere((m) => m.id == member.parentId);
        parent.childrenIds.remove(member.id);
      }
      
      void removeChildren(String memberId) {
        final children = members.where((m) => m.parentId == memberId).toList();
        for (var child in children) {
          removeChildren(child.id);
          members.remove(child);
          nodePositions.remove(child.id);
        }
      }
      
      removeChildren(member.id);
      
      members.remove(member);
      nodePositions.remove(member.id);
    });
  }

void _arrangeNodes() {
  const verticalGap = 200.0;
  const horizontalGap = 200.0;

  // Group members by generation
  Map<int, List<FamilyMember>> generationGroups = {};
  for (var member in members) {
    if (!generationGroups.containsKey(member.generation)) {
      generationGroups[member.generation] = [];
    }
    generationGroups[member.generation]!.add(member);
  }

  // Sort each generation group by parent-child relationship
  generationGroups.forEach((generation, membersInGen) {
    membersInGen.sort((a, b) {
      if (a.parentId == null && b.parentId == null) {
        return 0;
      } else if (a.parentId == null) {
        return -1;
      } else if (b.parentId == null) {
        return 1;
      } else {
        return a.parentId!.compareTo(b.parentId!);
      }
    });
  });

  // Position nodes
  double startX = 10000;
  generationGroups.forEach((generation, membersInGeneration) {
    double currentY = 10000 + (generation * verticalGap);
    double totalWidth = (membersInGeneration.length - 1) * horizontalGap;
    double currentX = startX - totalWidth / 2;

    for (var member in membersInGeneration) {
      nodePositions[member.id] = Offset(currentX, currentY);
      currentX += horizontalGap;
    }
  });
}

  void _centerTree() {
  if (nodePositions.isEmpty) return;

  final xPositions = nodePositions.values.map((pos) => pos.dx).toList();
  final yPositions = nodePositions.values.map((pos) => pos.dy).toList();

  final minX = xPositions.reduce((a, b) => a < b ? a : b);
  final maxX = xPositions.reduce((a, b) => a > b ? a : b);
  final minY = yPositions.reduce((a, b) => a < b ? a : b);
  final maxY = yPositions.reduce((a, b) => a > b ? a : b);

  final centerX = (minX + maxX) / 2;
  final centerY = (minY + maxY) / 2;

  final workspaceWidth = MediaQuery.of(context).size.width;
  final workspaceHeight = MediaQuery.of(context).size.height;

  final offsetX = workspaceWidth / 2 - centerX;
  final offsetY = workspaceHeight / 2 - centerY;

  setState(() {
    nodePositions = nodePositions.map((key, value) {
      return MapEntry(key, Offset(value.dx + offsetX, value.dy + offsetY));
    });
  });
}

  Future<void> importFromJson() async {
  try {
    // Pick a JSON file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      File file = File(filePath);
      String content = await file.readAsString();
      Map<String, dynamic> data = jsonDecode(content);

      // Parse members
      List<dynamic> memberList = data['members'];
      members = memberList.map((json) => FamilyMember.fromJson(json)).toList();

      // Parse positions
      Map<String, dynamic> positionsJson = data['positions'];
      nodePositions = positionsJson.map((key, value) {
        return MapEntry(
          key,
          Offset(value['x'], value['y']),
        );
      });

      _arrangeNodes();
      _saveState();

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import successful')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import failed: $e')),
    );
  }
}

  void _zoomToMember(FamilyMember member) {
  final position = nodePositions[member.id];
  if (position != null) {
    final scale = 1.0; // Adjust the scale as needed
    final matrix = Matrix4.identity()
      ..translate(-position.dx + MediaQuery.of(context).size.width / 2, -position.dy + MediaQuery.of(context).size.height / 2)
      ..scale(scale);
    _transformationController.value = matrix;
  }
}

  Future<void> exportToJson() async {
    try {
      final data = {
        'members': members.map((m) => m.toJson()).toList(),
        'positions': nodePositions.map((key, value) => MapEntry(
          key, {'x': value.dx, 'y': value.dy}
        )),
      };

      final tempDir = await getTemporaryDirectory();
      final fileName = 'family_tree_${DateTime.now().millisecondsSinceEpoch}.json';
      final tempFile = File('${tempDir.path}/$fileName');
      
      await tempFile.writeAsString(jsonEncode(data));
      
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Family Tree Data',
        text: 'Family Tree JSON Export',
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

@override
Widget build(BuildContext context) {
   return Scaffold(
    body: Stack(
      children: [
        //add background image link
        Container (
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://cdn2.fptshop.com.vn/unsafe/hinh_nen_rong_vang_3d_2_a1fee7d7c6.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          boundaryMargin: EdgeInsets.all(double.infinity),
          minScale: 0.01,
          maxScale: 5.0,
          child: Center( // Add Center widget here
            child: Container(
              width: 20000,
              height: 20000,
              color: Colors.white,
              child: Stack(
                // Add alignment to center the stack contents
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(20000, 20000),
                    painter: FamilyTreePainter(members, nodePositions),
                  ),
                  ...members.map((member) {
                    final position = nodePositions[member.id]!;
                    return Positioned(
                      left: position.dx - nodeWidth / 2,
                      top: position.dy - nodeHeight / 2,
                      child: GestureDetector(
                        onTap: () => _showMemberDialog(member),
                        child: Draggable(
                          feedback: Material(
                            color: Colors.transparent,
                            child: FamilyTreeNode(
                              member: member,
                              onAddChild: () {},
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.5,
                            child: FamilyTreeNode(
                              member: member,
                              onAddChild: () {},
                            ),
                          ),
                          child: FamilyTreeNode(
                            member: member,
                            onAddChild: () => addMember(member.id),
                          ),
                          onDragEnd: (details) {
                            setState(() {
                              final RenderBox renderBox = context.findRenderObject() as RenderBox;
                              final localPosition = renderBox.globalToLocal(details.offset);
                              nodePositions[member.id] = Offset(
                                10000 + (localPosition.dx - 10000), // Adjust for center
                                10000 + (localPosition.dy - 10000), // Adjust for center
                              );
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    floatingActionButton: SpeedDial(
      animatedIcon: AnimatedIcons.menu_close, // Biểu tượng nút chính
      backgroundColor: Colors.blue,
      children: [
        SpeedDialChild(
          child: Icon(Icons.person_add),
          label: 'Thêm thành viên',
          onTap: () => addMember(null),
        ),
        SpeedDialChild(
          child: Icon(Icons.share),
          label: 'Xuất JSON',
          onTap: exportToJson,
        ),
        SpeedDialChild(
          child: Icon(Icons.file_open),
          label: 'Nhập JSON',
          onTap: importFromJson,
        ),
        SpeedDialChild(
          child: Icon(Icons.delete),
          label: 'Xóa tất cả',
          onTap: _deleteAllMembers,
        ),
        SpeedDialChild(
          child: Icon(Icons.undo),
          label: 'Hoàn tác',
          onTap: undo,
        ),
        SpeedDialChild(
          child: Icon(Icons.redo),
          label: 'Làm lại',
          onTap: redo,
        ),
      ],
    ),
  );
}
  
}

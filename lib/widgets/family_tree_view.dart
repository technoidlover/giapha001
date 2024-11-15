import 'package:flutter/material.dart';
import '../models/family_member.dart';
import '../painters/family_tree_painter.dart';
import 'family_tree_node.dart';
import 'dart:math' show max;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class FamilyTreeView extends StatefulWidget {
  const FamilyTreeView({super.key});

  @override
  _FamilyTreeViewState createState() => _FamilyTreeViewState();
}

class _FamilyTreeViewState extends State<FamilyTreeView> {
  List<FamilyMember> members = [];
  Map<String, Offset> nodePositions = {};
  final double nodeWidth = 120.0;
  final double nodeHeight = 60.0;

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
    });
  }

  void _arrangeNodes() {
    const horizontalGap = 150.0;
    const verticalGap = 100.0;
    
    // Position root nodes
    var rootMembers = members.where((m) => m.parentId == null).toList();
    for (var i = 0; i < rootMembers.length; i++) {
      nodePositions[rootMembers[i].id] = Offset(
        MediaQuery.of(context).size.width / 2,
        100.0 + (i * verticalGap)
      );
    }

    // Position children
    for (var member in members.where((m) => m.parentId != null)) {
      var parent = members.firstWhere((m) => m.id == member.parentId);
      var parentPos = nodePositions[parent.id]!;
      var siblings = members.where((m) => m.parentId == parent.id).toList();
      var index = siblings.indexOf(member);
      
      nodePositions[member.id] = Offset(
        parentPos.dx + horizontalGap,
        parentPos.dy + (index - (siblings.length - 1) / 2) * verticalGap
      );
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

    // Get temp directory for sharing
    final tempDir = await getTemporaryDirectory();
    final fileName = 'family_tree_${DateTime.now().millisecondsSinceEpoch}.json';
    final tempFile = File('${tempDir.path}/$fileName');
    
    // Write JSON to temp file
    await tempFile.writeAsString(jsonEncode(data));

    // Share the file
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
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 2.0,
            child: CustomPaint(
              painter: FamilyTreePainter(members, nodePositions),
              child: Stack(
                children: members.map((member) {
                  final position = nodePositions[member.id] ?? Offset.zero;
                  return Positioned(
                    left: position.dx - nodeWidth/2,
                    top: position.dy - nodeHeight/2,
                    child: Draggable(
                      feedback: Material(
                        color: Colors.transparent,
                        child: FamilyTreeNode(
                          member: member,
                          onAddChild: () => addMember(member.id),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: FamilyTreeNode(
                          member: member,
                          onAddChild: () => addMember(member.id),
                        ),
                      ),
                      onDragEnd: (details) {
                        setState(() {
                          final RenderBox renderBox = context.findRenderObject() as RenderBox;
                          final localPosition = renderBox.globalToLocal(details.offset);
                          nodePositions[member.id] = localPosition + Offset(nodeWidth/2, nodeHeight/2);
                        });
                      },
                      child: FamilyTreeNode(
                        member: member,
                        onAddChild: () => addMember(member.id),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.menu, color: Colors.white),
              ),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'add_root',
                  child: ListTile(
                    leading: Icon(Icons.add),
                    title: Text('Add Root Member'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'clear',
                  child: ListTile(
                    leading: Icon(Icons.clear_all),
                    title: Text('Clear All'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'arrange',
                  child: ListTile(
                    leading: Icon(Icons.auto_fix_high),
                    title: Text('Auto Arrange'),
                  ),
                ),
                const PopupMenuItem<String>(
      value: 'export',
      child: ListTile(
        leading: Icon(Icons.download),
        title: Text('Export JSON'),
      ),
    ),
              ],
              onSelected: (String value) {
                switch (value) {
                  case 'add_root':
                    addMember(null);
                    break;
                  case 'clear':
                    setState(() {
                      members.clear();
                      nodePositions.clear();
                    });
                    break;
                  case 'arrange':
                    setState(() {
                      _arrangeNodes();
                    });
                    break;
                  case 'export':
                    exportToJson();
                  break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
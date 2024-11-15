import 'package:flutter/material.dart';
import '../models/family_member.dart';

class FamilyTreePainter extends CustomPainter {
  final List<FamilyMember> members;
  final Map<String, Offset> nodePositions;

  FamilyTreePainter(this.members, this.nodePositions);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var member in members) {
      if (member.parentId != null) {
        final parentPos = nodePositions[member.parentId];
        final childPos = nodePositions[member.id];
        
        if (parentPos != null && childPos != null) {
          canvas.drawLine(
            Offset(parentPos.dx, parentPos.dy + 60),
            Offset(childPos.dx, childPos.dy),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(FamilyTreePainter oldDelegate) => true;
}
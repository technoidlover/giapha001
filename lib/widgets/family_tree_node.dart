import 'package:flutter/material.dart';
import '../models/family_member.dart';

class FamilyTreeNode extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onAddChild;
  final double nodeWidth = 120.0;
  final double nodeHeight = 60.0;

  const FamilyTreeNode({
    super.key,
    required this.member,
    required this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: nodeWidth,
      height: nodeHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(
                member.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAddChild,
            child: Container(
              height: 24,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black12)),
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
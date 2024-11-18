import 'package:flutter/material.dart';
import '../models/family_member.dart';

class FamilyTreeNode extends StatefulWidget {
  final FamilyMember member;
  final VoidCallback onAddChild;

  const FamilyTreeNode({
    Key? key,
    required this.member,
    required this.onAddChild,
  }) : super(key: key);

  @override
  State<FamilyTreeNode> createState() => _FamilyTreeNodeState();
}

class _FamilyTreeNodeState extends State<FamilyTreeNode> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120.0,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: EdgeInsets.all(8),
              child: Text(
                widget.member.name,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.member.dateOfBirth != null)
                    Text('Born: ${widget.member.dateOfBirth!.year}'),
                  if (widget.member.dateOfDeath != null)
                    Text('Died: ${widget.member.dateOfDeath!.year}'),
                  if (widget.member.description != null)
                    Text(
                      widget.member.description!,
                      style: TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onAddChild,
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black12)),
              ),
              child: Icon(Icons.add, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
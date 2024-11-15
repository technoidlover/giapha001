import 'package:flutter/material.dart';
import 'widgets/family_tree_view.dart';
import 'package:path_provider/path_provider.dart';
void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: FamilyTreeView(),
    ),
  ));
}
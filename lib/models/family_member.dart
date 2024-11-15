// class FamilyMember {
//   final String id;
//   final String name;
//   String? parentId;
//   List<String> childrenIds;
//   int generation;

//   FamilyMember({
//     required this.id,
//     required this.name,
//     this.parentId,
//     this.childrenIds = const [],
//     this.generation = 0,
//   });
// }
// In family_member.dart
class FamilyMember {
  final String id;
  final String name;
  String? parentId;
  List<String> childrenIds; // Remove const
  int generation;

  FamilyMember({
    required this.id,
    required this.name,
    this.parentId,
    List<String>? childrenIds, // Make parameter optional
    this.generation = 0,
  }) : childrenIds = childrenIds ?? []; // Initialize with empty mutable list

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'parentId': parentId,
    'childrenIds': childrenIds,
    'generation': generation,
  };

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'],
    name: json['name'],
    parentId: json['parentId'],
    childrenIds: List<String>.from(json['childrenIds']),
    generation: json['generation'],
  );
}
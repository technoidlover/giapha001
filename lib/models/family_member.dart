class FamilyMember {
  String id;
  String name;
  String? parentId;
  List<String> childrenIds;
  int generation;

  // New fields
  DateTime? dateOfBirth;
  DateTime? dateOfDeath;
  String? imageUrl;
  String? description;

  FamilyMember({
    required this.id,
    required this.name,
    this.parentId,
    List<String>? childrenIds,
    this.generation = 0,
    this.dateOfBirth,
    this.dateOfDeath,
    this.imageUrl,
    this.description,
  }) : childrenIds = childrenIds ?? [];

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentId': parentId,
        'childrenIds': childrenIds,
        'generation': generation,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'dateOfDeath': dateOfDeath?.toIso8601String(),
        'imageUrl': imageUrl,
        'description': description,
      };

  // Create from JSON
  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
        id: json['id'],
        name: json['name'],
        parentId: json['parentId'],
        childrenIds: List<String>.from(json['childrenIds']),
        generation: json['generation'],
        dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
        dateOfDeath: json['dateOfDeath'] != null ? DateTime.parse(json['dateOfDeath']) : null,
        imageUrl: json['imageUrl'],
        description: json['description'],
      );

  // Clone method
  FamilyMember clone() {
    return FamilyMember(
      id: id,
      name: name,
      parentId: parentId,
      childrenIds: List<String>.from(childrenIds),
      generation: generation,
      dateOfBirth: dateOfBirth,
      dateOfDeath: dateOfDeath,
      imageUrl: imageUrl,
      description: description,
    );
  }
}

class Goal {
  Goal({
    required this.id,
    required this.name,
    required this.description,
    required this.targetDate,
    required this.isCompleted,
    required this.createdDate,
  });

  final String id;
  final String name;
  final String description;
  final DateTime targetDate;
  final bool isCompleted;
  final DateTime createdDate;

  Goal copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? createdDate,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  Map<String, Object?> toMap({String? userId}) {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetDate': targetDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'createdDate': createdDate.toIso8601String(),
      'userId': userId ?? '',
    };
  }

  static Goal fromMap(Map<String, Object?> map) {
    return Goal(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      targetDate: DateTime.parse(map['targetDate'] as String),
      isCompleted: (map['isCompleted'] as int) == 1,
      createdDate: DateTime.parse(map['createdDate'] as String),
    );
  }
}

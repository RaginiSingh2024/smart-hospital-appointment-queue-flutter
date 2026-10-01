class Department {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final bool isActive;
  final int totalDoctors;
  final String headDoctorName;

  const Department({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isActive = true,
    this.totalDoctors = 0,
    this.headDoctorName = '',
  });

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      isActive: map['isActive'] as bool? ?? true,
      totalDoctors: map['totalDoctors'] as int? ?? 0,
      headDoctorName: map['headDoctorName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'isActive': isActive,
      'totalDoctors': totalDoctors,
      'headDoctorName': headDoctorName,
    };
  }

  Department copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    bool? isActive,
    int? totalDoctors,
    String? headDoctorName,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      totalDoctors: totalDoctors ?? this.totalDoctors,
      headDoctorName: headDoctorName ?? this.headDoctorName,
    );
  }
}

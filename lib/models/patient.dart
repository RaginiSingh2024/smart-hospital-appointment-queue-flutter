class PatientModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final DateTime? dateOfBirth;
  final String bloodGroup;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? profileImageUrl;
  final List<String> allergies;
  final String? address;
  final bool isActive;

  const PatientModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    required this.bloodGroup,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.profileImageUrl,
    this.allergies = const [],
    this.address,
    this.isActive = true,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      bloodGroup: map['bloodGroup'] as String? ?? 'O+',
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      allergies: List<String>.from(map['allergies'] as List? ?? []),
      address: map['address'] as String?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'bloodGroup': bloodGroup,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'profileImageUrl': profileImageUrl,
      'allergies': allergies,
      'address': address,
      'isActive': isActive,
    };
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  PatientModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? profileImageUrl,
    List<String>? allergies,
    String? address,
    bool? isActive,
  }) {
    return PatientModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      allergies: allergies ?? this.allergies,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
    );
  }
}

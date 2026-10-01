class Doctor {
  final String id;
  final String userId;
  final String name;
  final String specialty;
  final String departmentId;
  final String departmentName;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final double consultationFee;
  final String qualification;
  final String about;
  final String? profileImageUrl;
  final bool isAvailable;
  final bool isActive;
  final List<String> availableDays;
  final Map<String, List<String>> weeklySlots; // day -> list of time slots
  final String registrationNumber;
  final String email;
  final String phone;
  final String? roomNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Doctor({
    required this.id,
    required this.userId,
    required this.name,
    required this.specialty,
    required this.departmentId,
    required this.departmentName,
    required this.experienceYears,
    required this.rating,
    required this.reviewCount,
    required this.consultationFee,
    required this.qualification,
    required this.about,
    this.profileImageUrl,
    this.isAvailable = true,
    this.isActive = true,
    required this.availableDays,
    required this.weeklySlots,
    required this.registrationNumber,
    required this.email,
    required this.phone,
    this.roomNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      specialty: map['specialty'] as String,
      departmentId: map['departmentId'] as String,
      departmentName: map['departmentName'] as String,
      experienceYears: map['experienceYears'] as int,
      rating: (map['rating'] as num).toDouble(),
      reviewCount: map['reviewCount'] as int,
      consultationFee: (map['consultationFee'] as num).toDouble(),
      qualification: map['qualification'] as String,
      about: map['about'] as String,
      profileImageUrl: map['profileImageUrl'] as String?,
      isAvailable: map['isAvailable'] as bool? ?? true,
      isActive: map['isActive'] as bool? ?? true,
      availableDays: List<String>.from(map['availableDays'] as List),
      weeklySlots: Map<String, List<String>>.from(
        (map['weeklySlots'] as Map).map(
          (k, v) => MapEntry(k as String, List<String>.from(v as List)),
        ),
      ),
      registrationNumber: map['registrationNumber'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      roomNumber: map['roomNumber'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'specialty': specialty,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'experienceYears': experienceYears,
      'rating': rating,
      'reviewCount': reviewCount,
      'consultationFee': consultationFee,
      'qualification': qualification,
      'about': about,
      'profileImageUrl': profileImageUrl,
      'isAvailable': isAvailable,
      'isActive': isActive,
      'availableDays': availableDays,
      'weeklySlots': weeklySlots,
      'registrationNumber': registrationNumber,
      'email': email,
      'phone': phone,
      'roomNumber': roomNumber,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Doctor copyWith({
    String? id,
    String? userId,
    String? name,
    String? specialty,
    String? departmentId,
    String? departmentName,
    int? experienceYears,
    double? rating,
    int? reviewCount,
    double? consultationFee,
    String? qualification,
    String? about,
    String? profileImageUrl,
    bool? isAvailable,
    bool? isActive,
    List<String>? availableDays,
    Map<String, List<String>>? weeklySlots,
    String? registrationNumber,
    String? email,
    String? phone,
    String? roomNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Doctor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      experienceYears: experienceYears ?? this.experienceYears,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      consultationFee: consultationFee ?? this.consultationFee,
      qualification: qualification ?? this.qualification,
      about: about ?? this.about,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      availableDays: availableDays ?? this.availableDays,
      weeklySlots: weeklySlots ?? this.weeklySlots,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roomNumber: roomNumber ?? this.roomNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

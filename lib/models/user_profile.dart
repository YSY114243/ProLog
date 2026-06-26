class UserProfile {
  final String id;
  final String fullName;
  final String role;
  final String? supervisorId;
  final String? uniId;
  final String? major;
  final String? uniName;
  final String? company;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.supervisorId,
    this.uniId,
    this.major,
    this.uniName,
    this.company,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Unknown Student',
      role: json['role'] as String? ?? 'student',
      supervisorId: json['supervisor_id'] as String?,
      uniId: json['uni_id'] as String?,
      major: json['major'] as String?,
      uniName: json['uni_name'] as String?,
      company: json['company'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      if (supervisorId != null) 'supervisor_id': supervisorId,
      if (uniId != null) 'uni_id': uniId,
      if (major != null) 'major': major,
      if (uniName != null) 'uni_name': uniName,
      if (company != null) 'company': company,
    };
  }
}

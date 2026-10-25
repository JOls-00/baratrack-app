class UserModel {
  final int id;
  final int? residentId;
  final String name;
  final String? username;
  final String? idNumber;
  final String email;
  final String role;
  final String status;
  final String? contactNumber;
  final String? address;
  final String? profilePicture;
  final DateTime? birthDate;

  UserModel({
    required this.id,
    this.residentId,
    required this.name,
    this.username,
    this.idNumber,
    required this.email,
    required this.role,
    required this.status,
    this.contactNumber,
    this.address,
    this.profilePicture,
    this.birthDate,
  });

  UserModel copyWith({
    int? residentId,
    String? name,
    String? username,
    String? idNumber,
    String? email,
    String? contactNumber,
    String? address,
    String? profilePicture,
    DateTime? birthDate,
  }) {
    return UserModel(
      id: id,
      residentId: residentId ?? this.residentId,
      name: name ?? this.name,
      username: username ?? this.username,
      idNumber: idNumber ?? this.idNumber,
      email: email ?? this.email,
      role: role,
      status: status,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      profilePicture: profilePicture ?? this.profilePicture,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      residentId: json['resident_id'],
      name: json['name'],
      username: json['username'],
      idNumber: json['id_number'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
      contactNumber: json['contact_number'],
      address: json['address'],
      profilePicture: json['profile_picture'],
      birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resident_id': residentId,
      'name': name,
      'username': username,
      'id_number': idNumber,
      'email': email,
      'role': role,
      'status': status,
      'contact_number': contactNumber,
      'address': address,
      'profile_picture': profilePicture,
      'birth_date': birthDate?.toIso8601String(),
    };
  }
}

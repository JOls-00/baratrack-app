class ResidentModel {
  final int id;
  final int? userId;
  final String firstName;
  final String lastName;
  final String middleName;
  final String suffix;
  final String? gender;
  final DateTime? birthDate;
  final String? contact;
  final String? email;
  final String? address;
  final String? zone;
  final String status; // Active, Deceased, Relocated
  final DateTime? createdAt;

  ResidentModel({
    required this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    this.middleName = '',
    this.suffix = '',
    this.gender,
    this.birthDate,
    this.contact,
    this.email = '',
    this.address,
    this.zone,
    this.status = 'Active',
    this.createdAt,
  });

  String get fullName => '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName${suffix.isNotEmpty ? ' $suffix' : ''}';

  factory ResidentModel.fromJson(Map<String, dynamic> json) {
    return ResidentModel(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      suffix: json['suffix'] ?? '',
      gender: json['gender'],
      birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date']) : null,
      contact: json['contact'],
      email: json['email'] ?? '',
      address: json['address'],
      zone: json['zone'],
      status: json['status'] ?? 'Active',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

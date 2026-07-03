class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? mobileNumber;
  final String role;
  final bool isBlocked;
  final String? emailVerifiedAt;
  final String? mobileVerifiedAt;
  final String? referralCode;
  final String? referredBy;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.mobileNumber,
    required this.role,
    required this.isBlocked,
    this.emailVerifiedAt,
    this.mobileVerifiedAt,
    this.referralCode,
    this.referredBy,
  });

  bool get isAdmin => role == 'admin';
  bool get isEmailVerified => emailVerifiedAt != null;
  bool get isMobileVerified => mobileVerifiedAt != null;

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as int,
    name: j['name'] as String,
    email: j['email'] as String,
    avatar: j['avatar'] as String?,
    mobileNumber: j['mobile_number'] as String?,
    role: j['role'] as String? ?? 'user',
    isBlocked: j['is_blocked'] as bool? ?? false,
    emailVerifiedAt: j['email_verified_at'] as String?,
    mobileVerifiedAt: j['mobile_verified_at'] as String?,
    referralCode: j['referral_code'] as String?,
    referredBy: j['referred_by']?.toString(),
  );

  User copyWith({String? name, String? avatar, String? mobileNumber}) => User(
    id: id,
    name: name ?? this.name,
    email: email,
    avatar: avatar ?? this.avatar,
    mobileNumber: mobileNumber ?? this.mobileNumber,
    role: role,
    isBlocked: isBlocked,
    emailVerifiedAt: emailVerifiedAt,
    mobileVerifiedAt: mobileVerifiedAt,
    referralCode: referralCode,
    referredBy: referredBy,
  );
}

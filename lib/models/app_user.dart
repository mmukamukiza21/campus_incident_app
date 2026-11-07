
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  // Account role checks
  bool get isStudent => role == 'student';

  bool get isAdmin => role == 'admin';

  bool get isResponder => role == 'responder' || role == 'staff';

  // Keeps compatibility with existing staff checks.
  bool get isStaff => isAdmin || isResponder;

  // Role display name
  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'responder':
      case 'staff':
        return 'Responder';
      default:
        return 'Student';
    }
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString().toLowerCase() ?? 'student',
    );
  }
}

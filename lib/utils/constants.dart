class AppConstants {
  static const allowedDomains = ['alustudent.com', 'alueducation.com'];
  static const roleStudent = 'student';
  static const roleStaff = 'staff';

  static bool isAluEmail(String email) {
    final e = email.trim().toLowerCase();
    return allowedDomains.any((d) => e.endsWith('@$d'));
  }
}
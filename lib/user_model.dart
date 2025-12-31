class AppUser {
  final String id;
  final String fullName;
  final String department;
  final int score; // The score calculated by your algorithm

  AppUser({required this.id, required this.fullName, required this.department, required this.score});
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      fullName: json['full_name'],
      department: json['department'],
      score: json['score'] ?? 0, // Default to 0 if null
    );
  }
}
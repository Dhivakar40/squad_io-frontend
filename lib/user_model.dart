class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String department;
  final String year;
  final String bio;
  final int score;
  final List<String> skills; // Added skills support

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.department,
    required this.year,
    required this.bio,
    required this.score,
    required this.skills,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      // 1. SAFETY CHECKS: Use '??' to handle NULL values
      id: json['id']?.toString() ?? '',

      // If name is missing, show "Unknown User"
      fullName: json['full_name'] ?? 'Unknown User',

      email: json['email'] ?? '',

      // If department is missing, show "General"
      department: json['department'] ?? 'General',

      // Handle Year (it might be an Int in DB, but we want String in UI)
      year: (json['year_of_study'] ?? 0).toString(),

      bio: json['bio'] ?? '',

      // Match Score (Default to 0)
      score: json['match_score'] ?? 0,

      // Handle Skills List (safely parse the array)
      skills: (json['skills'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ??
          [],
    );
  }
}
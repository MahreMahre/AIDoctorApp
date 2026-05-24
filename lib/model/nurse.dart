class Nurse {
  final String id;
  final String name;
  final String imageUrl;
  final String specialization;
  final double rating;
  final int experienceYears;
  final String bio;
  final bool isAvailable;

  Nurse({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.specialization,
    required this.rating,
    required this.experienceYears,
    required this.bio,
    this.isAvailable = true,
  });

  factory Nurse.fromMap(Map<String, dynamic> data, String id) {
    return Nurse(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      specialization: data['specialization'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      experienceYears: data['experienceYears'] ?? 0,
      bio: data['bio'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
    );
  }
}
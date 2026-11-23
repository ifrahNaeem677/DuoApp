/// A person in the duo (you or your friend).
/// Later this can be saved to / loaded from Firebase.
class AppUser {
  String name;
  final String pairCode;

  AppUser({required this.name, required this.pairCode});

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
}

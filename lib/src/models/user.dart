class User {
  String username;
  String photoUrl;
  late String _id;
  bool active;
  DateTime lastSeen;

  String get id => _id;
  User({
    required this.username,
    required this.photoUrl,
    required this.active,
    required this.lastSeen,
  });

  toJson() => {
        'username': username,
        'photo_url': photoUrl,
        'active': active,
        'last_seen': lastSeen
      };

  factory User.fromJson(Map<String, dynamic> json) {
    final user = User(
        username: json['username'],
        photoUrl: json['photo_url'],
        active: json['active'],
        lastSeen: json['last_seen']);
    user._id = json['id'];
    return user;
  }
}

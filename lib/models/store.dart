class Store {
  final int id;
  final String displayName;
  final String profile;

  Store({
    required this.id,
    required this.displayName,
    required this.profile,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      displayName: json['displayName'] ?? 'Unknown Store',
      profile: json['profile'] ?? '',
    );
  }
}

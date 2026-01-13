class Waiter {
  final int id;
  final String name;

  Waiter({
    required this.id,
    required this.name,
  });

  factory Waiter.fromJson(Map<String, dynamic> json) {
    return Waiter(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

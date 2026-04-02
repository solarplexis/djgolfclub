class Player {
  final int? id;
  final String name;

  const Player({this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory Player.fromMap(Map<String, dynamic> map) =>
      Player(id: map['id'] as int?, name: map['name'] as String);
}

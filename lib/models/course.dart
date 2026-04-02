class Hole {
  final int number;
  final int par;

  const Hole({required this.number, required this.par});

  Map<String, dynamic> toMap() => {'number': number, 'par': par};

  factory Hole.fromMap(Map<String, dynamic> map) =>
      Hole(number: map['number'] as int, par: map['par'] as int);
}

class Course {
  final int? id;
  final String name;
  final List<Hole> holes;

  const Course({this.id, required this.name, required this.holes});

  int get totalPar => holes.fold(0, (sum, h) => sum + h.par);
  int get holeCount => holes.length;

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}

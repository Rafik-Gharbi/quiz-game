import 'package:quiz_game/utils/helper.dart';

class Student {
  final String uid;
  final String name;
  final String? joinedAt;

  Student({required this.uid, required this.name, this.joinedAt});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      uid: json['uid'] ?? json['id'],
      name: json['name'],
      joinedAt: Helper.joinedTime(json['joinedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'joinedAt': joinedAt,
  };
}

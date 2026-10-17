import 'package:mini_app/models/json_readers.dart';

/// Пользователь Telegram.
class User {
  const User({required this.id, required this.firstName});

  factory User.fromJson(Map<String, Object?> json) {
    return User(
      id: readInt(json['id']),
      firstName: readString(json['first_name']).trim(),
    );
  }

  final int id;
  final String firstName;

  /// Имя для приветствия; пустая строка, если имя не пришло.
  String get displayName => firstName;
}

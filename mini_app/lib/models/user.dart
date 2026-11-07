import 'package:mini_app/models/json_readers.dart';

/// Кто занимается: от этого зависят упражнения и тон текстов.
enum UserAudience {
  child('child'),
  adult('adult');

  const UserAudience(this.apiValue);

  final String apiValue;

  static UserAudience? fromApi(Object? value) {
    for (final UserAudience audience in UserAudience.values) {
      if (audience.apiValue == value) {
        return audience;
      }
    }
    return null;
  }
}

/// Пользователь Telegram и его профиль.
class User {
  const User({
    required this.id,
    required this.firstName,
    this.audience,
    this.consentVersion,
  });

  factory User.fromJson(Map<String, Object?> json) {
    return User(
      id: readInt(json['id']),
      firstName: readString(json['first_name']).trim(),
      audience: UserAudience.fromApi(json['audience']),
      consentVersion: readOptionalInt(json['consent_version']),
    );
  }

  final int id;
  final String firstName;

  /// null — пользователь ещё не выбрал, кто занимается.
  final UserAudience? audience;

  /// Версия принятого согласия; null — согласия ещё нет.
  final int? consentVersion;

  /// Имя для приветствия; пустая строка, если имя не пришло.
  String get displayName => firstName;

  User copyWith({UserAudience? audience, int? consentVersion}) {
    return User(
      id: id,
      firstName: firstName,
      audience: audience ?? this.audience,
      consentVersion: consentVersion ?? this.consentVersion,
    );
  }
}

import 'package:mini_app/models/json_readers.dart';
import 'package:mini_app/models/user.dart';

/// Ответ `POST /api/auth/telegram`.
class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, Object?> json) {
    final Object? rawUser = json['user'];
    return AuthResponse(
      token: readString(json['token']),
      user: rawUser is Map<Object?, Object?>
          ? User.fromJson(rawUser.cast<String, Object?>())
          : const User(id: 0, firstName: ''),
    );
  }

  final String token;
  final User user;
}

import 'package:flutter/foundation.dart';
import 'package:mini_app/core/api_client.dart';
import 'package:mini_app/core/api_exception.dart';
import 'package:mini_app/core/constants.dart';
import 'package:mini_app/core/telegram_bridge.dart';
import 'package:mini_app/models/auth_response.dart';
import 'package:mini_app/models/user.dart';

/// Состояние авторизации.
enum AuthStatus { idle, loading, authenticated, error }

/// Причина ошибки входа.
enum AuthErrorKind { none, noTelegram, network, unauthorized, unknown }

/// Авторизация через Telegram `initData`.
class AuthService extends ChangeNotifier {
  AuthService({required this.api, required this.telegram});

  final ApiClient api;
  final TelegramBridge telegram;

  AuthStatus _status = AuthStatus.idle;
  AuthErrorKind _errorKind = AuthErrorKind.none;
  String? _errorMessage;
  User? _user;
  bool _isDemo = false;
  bool _forceDemo = false;

  AuthStatus get status => _status;
  AuthErrorKind get errorKind => _errorKind;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  bool get isDemo => _isDemo;

  /// Можно ли предложить демо-режим в текущей сборке.
  bool get canUseDemo => kDebugMode || useMockApi;

  /// Войти через Telegram или в демо-режиме.
  Future<void> signIn() async {
    if (_status == AuthStatus.loading) {
      return;
    }

    _status = AuthStatus.loading;
    _errorKind = AuthErrorKind.none;
    _errorMessage = null;
    notifyListeners();

    final String initData = telegram.initData;
    final bool demo =
        api.isMock || _forceDemo || (kDebugMode && initData.isEmpty);

    if (demo && !api.isMock) {
      api.enableMockMode();
    }

    if (initData.isEmpty && !demo) {
      _fail(
        AuthErrorKind.noTelegram,
        'Откройте приложение через Telegram — так мы узнаем, кто вы.',
      );
      return;
    }

    try {
      final AuthResponse response = await api.authTelegram(initData);
      if (response.token.isEmpty) {
        _fail(
          AuthErrorKind.unknown,
          'Сервер не выдал токен доступа. Попробуйте ещё раз.',
        );
        return;
      }

      api.setToken(response.token);
      _user = response.user;
      _isDemo = api.isMock;
      _status = AuthStatus.authenticated;
      _errorKind = AuthErrorKind.none;
      _errorMessage = null;
      notifyListeners();
    } on ApiException catch (error) {
      debugPrint('Auth failed: $error');
      if (error.isNetwork || error.isTimeout) {
        _fail(
          AuthErrorKind.network,
          'Нет связи с сервером. Проверьте интернет и попробуйте снова.',
        );
      } else if (error.isUnauthorized) {
        _fail(
          AuthErrorKind.unauthorized,
          'Не удалось подтвердить аккаунт. Откройте приложение заново.',
        );
      } else {
        _fail(AuthErrorKind.unknown, error.userMessage);
      }
    } catch (error) {
      debugPrint('Auth failed unexpectedly: $error');
      _fail(
        AuthErrorKind.unknown,
        'Что-то пошло не так. Попробуйте войти ещё раз.',
      );
    }
  }

  /// Включить демо-режим (для отладки и показа без backend).
  Future<void> signInAsDemo() async {
    _forceDemo = true;
    await signIn();
  }

  void _fail(AuthErrorKind kind, String message) {
    _status = AuthStatus.error;
    _errorKind = kind;
    _errorMessage = message;
    notifyListeners();
  }
}

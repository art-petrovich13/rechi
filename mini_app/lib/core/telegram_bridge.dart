import 'package:flutter/widgets.dart';
import 'package:mini_app/core/telegram_bridge_stub.dart'
    if (dart.library.js_interop) 'package:mini_app/core/telegram_bridge_web.dart';

/// Связь с Telegram Mini App.
///
/// Реализация выбирается при сборке: в web — настоящий Telegram SDK,
/// в тестах и мобильных сборках — заглушка. Поэтому экраны не зависят
/// от `dart:js_interop`.
abstract interface class TelegramBridge {
  factory TelegramBridge() => createTelegramBridge();

  /// Открыто ли приложение внутри Telegram.
  bool get isInsideTelegram;

  /// Сырая строка `Telegram.WebApp.initData`; пустая вне Telegram.
  String get initData;

  /// Сообщает Telegram, что интерфейс готов, и настраивает окно.
  void initialize();

  /// Просит подтверждение перед закрытием, пока идёт запись или проверка.
  void setClosingConfirmation({required bool enabled});

  /// Показывает системную кнопку «Назад» Telegram; null — скрывает.
  void setBackAction(VoidCallback? onBack);
}

/// Показывает кнопку «Назад» Telegram, когда в стеке больше одного экрана.
class TelegramBackButtonObserver extends NavigatorObserver {
  TelegramBackButtonObserver(this._telegram);

  final TelegramBridge _telegram;
  int _depth = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _depth++;
    _sync();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _depth--;
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _depth--;
    _sync();
  }

  void _sync() {
    final NavigatorState? state = navigator;
    _telegram.setBackAction(
      _depth > 1 && state != null ? state.maybePop : null,
    );
  }
}

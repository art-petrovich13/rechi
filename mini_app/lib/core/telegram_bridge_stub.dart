import 'package:flutter/widgets.dart';
import 'package:mini_app/core/telegram_bridge.dart';

/// Вне браузера Telegram недоступен: тесты и мобильные сборки.
TelegramBridge createTelegramBridge() => NoTelegramBridge();

/// Мост без Telegram: все действия ничего не делают.
class NoTelegramBridge implements TelegramBridge {
  @override
  bool get isInsideTelegram => false;

  @override
  String get initData => '';

  @override
  void initialize() {}

  @override
  void setClosingConfirmation({required bool enabled}) {}

  @override
  void setBackAction(VoidCallback? onBack) {}
}

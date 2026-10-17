import 'package:flutter/foundation.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:telegram_web_app/telegram_web_app.dart';

/// Безопасная обёртка над Telegram WebApp SDK.
///
/// Все вызовы защищены: приложение должно открываться и в обычном браузере
/// (для разработки и демо), где Telegram-объекта может не быть.
class TelegramBridge {
  bool _initialized = false;

  /// Открыто ли приложение внутри Telegram.
  bool get isInsideTelegram {
    try {
      return TelegramWebApp.instance.isSupported;
    } catch (error) {
      debugPrint('Telegram isSupported failed: $error');
      return false;
    }
  }

  /// Сырая строка `Telegram.WebApp.initData`.
  ///
  /// Пустая строка, если приложение открыто вне Telegram или данных нет.
  String get initData {
    if (!isInsideTelegram) {
      return '';
    }
    try {
      return TelegramWebApp.instance.initData.raw;
    } catch (error) {
      debugPrint('Telegram initData failed: $error');
      return '';
    }
  }

  /// Сообщает Telegram, что интерфейс готов, и разворачивает Mini App.
  void initialize() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    if (!isInsideTelegram) {
      return;
    }

    try {
      final TelegramWebApp app = TelegramWebApp.instance;
      app.ready();
      app.expand();
      app.setHeaderColor(AppColors.backgroundTop);
      app.setBackgroundColor(AppColors.backgroundTop);
      if (app.isVersionAtLeast('7.10')) {
        app.setBottomBarColor(AppColors.backgroundTop);
      }
    } catch (error) {
      debugPrint('Telegram initialize failed: $error');
    }
  }
}

import 'package:flutter/widgets.dart';
import 'package:mini_app/core/telegram_bridge.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:telegram_web_app/telegram_web_app.dart';

/// Мост к Telegram для web-сборки.
TelegramBridge createTelegramBridge() => WebTelegramBridge();

/// Безопасная обёртка над Telegram WebApp SDK.
///
/// Все вызовы защищены: приложение должно открываться и в обычном браузере
/// (для разработки и демо), где Telegram-объекта может не быть.
class WebTelegramBridge implements TelegramBridge {
  bool _initialized = false;
  bool _backHandlerRegistered = false;
  VoidCallback? _onBack;

  /// Открыто ли приложение внутри Telegram.
  @override
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
  @override
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
  @override
  void initialize() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    if (!isInsideTelegram) {
      return;
    }

    _safely('initialize', () {
      final TelegramWebApp app = TelegramWebApp.instance;
      app.ready();
      app.expand();
      app.setHeaderColor(AppColors.backgroundTop);
      app.setBackgroundColor(AppColors.backgroundTop);
      if (app.isVersionAtLeast('7.7')) {
        // Прокрутка длинных экранов иначе сворачивает Mini App.
        app.disableVerticalSwipes();
      }
      if (app.isVersionAtLeast('7.10')) {
        app.setBottomBarColor(AppColors.backgroundTop);
      }
    });
  }

  /// Просит подтверждение перед закрытием, пока идёт запись или проверка.
  @override
  void setClosingConfirmation({required bool enabled}) {
    if (!isInsideTelegram) {
      return;
    }
    _safely('closing confirmation', () {
      final TelegramWebApp app = TelegramWebApp.instance;
      if (enabled) {
        app.enableClosingConfirmation();
      } else {
        app.disableClosingConfirmation();
      }
    });
  }

  /// Показывает системную кнопку «Назад» Telegram; null — скрывает.
  @override
  void setBackAction(VoidCallback? onBack) {
    _onBack = onBack;
    if (!isInsideTelegram) {
      return;
    }
    _safely('back button', () {
      final BackButton button = TelegramWebApp.instance.backButton;
      // offClick в SDK-обёртке не снимает обработчик, поэтому регистрируем
      // его один раз и вызываем текущее действие.
      if (!_backHandlerRegistered) {
        button.onClick(() => _onBack?.call());
        _backHandlerRegistered = true;
      }
      if (onBack == null) {
        button.hide();
      } else {
        button.show();
      }
    });
  }

  void _safely(String action, VoidCallback body) {
    try {
      body();
    } catch (error) {
      debugPrint('Telegram $action failed: $error');
    }
  }
}

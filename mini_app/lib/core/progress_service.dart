import 'package:flutter/foundation.dart';
import 'package:mini_app/core/api_client.dart';
import 'package:mini_app/core/api_exception.dart';
import 'package:mini_app/models/progress.dart';

/// Загрузка и состояние прогресса пользователя.
class ProgressService extends ChangeNotifier {
  ProgressService({required this.api});

  final ApiClient api;

  Progress? _progress;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  Progress? get progress => _progress;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;

  /// Загрузить прогресс. [silent] — без очистки ошибки перед запросом.
  Future<void> load({bool silent = false}) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    if (!silent) {
      _errorMessage = null;
    }
    notifyListeners();

    try {
      _progress = await api.progress();
      _errorMessage = null;
    } on ApiException catch (error) {
      debugPrint('Progress failed: $error');
      _errorMessage = error.userMessage;
    } catch (error) {
      debugPrint('Progress failed unexpectedly: $error');
      _errorMessage = 'Не удалось загрузить прогресс. Попробуйте ещё раз.';
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  /// Сбросить состояние, например при выходе из аккаунта.
  void reset() {
    _progress = null;
    _errorMessage = null;
    _isLoading = false;
    _hasLoaded = false;
    notifyListeners();
  }
}

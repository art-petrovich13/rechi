import 'package:web/web.dart' as web;

/// Освобождает память, занятую записью в браузере.
void revokeObjectUrl(String url) {
  if (url.startsWith('blob:')) {
    web.URL.revokeObjectURL(url);
  }
}

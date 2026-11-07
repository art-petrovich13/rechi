/// Освобождение blob-адресов записи: на web это `URL.revokeObjectURL`.
library;

export 'object_url_stub.dart'
    if (dart.library.js_interop) 'object_url_web.dart';

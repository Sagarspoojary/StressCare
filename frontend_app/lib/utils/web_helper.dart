// Conditional import to separate web-only code from mobile
export 'web_stub.dart'
    if (dart.library.html) 'web_impl.dart';

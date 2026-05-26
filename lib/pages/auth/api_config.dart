import 'package:flutter/foundation.dart';

/// Shared API base URL for all Flutter clients (judge + viewer).
///
/// Override with:
/// `--dart-define=API_BASE_URL=http://<your-host>:8000`
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
const String _defaultLocalNetworkApiBaseUrl = 'http://10.102.147.188:8000';

final String _initialApiBaseUrl = _resolveDefaultApiBaseUrl();
String _runtimeApiBaseUrl = _initialApiBaseUrl;

String get defaultApiBaseUrl => _runtimeApiBaseUrl;
String get initialApiBaseUrl => _initialApiBaseUrl;

String _resolveDefaultApiBaseUrl() {
  if (_apiBaseUrlOverride.isNotEmpty) {
    return _normalizeApiBaseUrl(_apiBaseUrlOverride);
  }

  if (kIsWeb) {
    final host = Uri.base.host;
    if (host.isNotEmpty) {
      final scheme = Uri.base.scheme == 'https' ? 'https' : 'http';
      return _normalizeApiBaseUrl('$scheme://$host:8000');
    }
  }

  return _normalizeApiBaseUrl(_defaultLocalNetworkApiBaseUrl);
}

void setApiBaseUrl(String value) {
  _runtimeApiBaseUrl = _normalizeApiBaseUrl(value);
}

bool isValidApiBaseUrl(String value) {
  final normalizedValue = _normalizeApiBaseUrl(value);
  final uri = Uri.tryParse(normalizedValue);
  return uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

String _normalizeApiBaseUrl(String value) {
  return value.trim().replaceFirst(RegExp(r'\/+$'), '');
}

Uri apiUri(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$defaultApiBaseUrl$normalizedPath');
}

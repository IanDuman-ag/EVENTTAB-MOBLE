/// Shared API base URL for all Flutter clients (judge + viewer).
const String defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

Uri apiUri(String path) => Uri.parse('$defaultApiBaseUrl$path');

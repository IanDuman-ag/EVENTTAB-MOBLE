// Shared app configuration constants.
// auth_service.dart, shell.dart and any other file that needs the base URL
// should import this file instead of main.dart to avoid circular imports.

const String defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

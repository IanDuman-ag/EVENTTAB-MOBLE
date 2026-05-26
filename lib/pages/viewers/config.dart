// Viewer pages should reuse the shared auth API config so all clients resolve
// the same backend URL and runtime override.

export '../auth/api_config.dart' show apiUri, defaultApiBaseUrl;

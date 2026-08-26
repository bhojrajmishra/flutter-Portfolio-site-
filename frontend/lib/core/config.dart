/// API base URL, e.g. "http://localhost:3000/api" for local dev or
/// "/api" (default) for production, where Nginx proxies /api on the same
/// origin as the Flutter build. Override at build/run time with:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '/api',
);

/// Base URL uploaded files (images, resume) are served from. Derived from
/// [apiBaseUrl] by stripping the trailing "/api" so it works the same way
/// in dev and prod without a second flag, but can be overridden directly.
String get uploadsBaseUrl {
  const override = String.fromEnvironment('UPLOADS_BASE_URL');
  if (override.isNotEmpty) return override;
  return apiBaseUrl.endsWith('/api')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - '/api'.length)
      : apiBaseUrl;
}

import 'package:dio/dio.dart';

import '../auth/auth.dart';

/// Dio for the generated API client: 10 s timeouts and the user's access token as a Bearer header
/// (NFR-004). `supabase_flutter` keeps the token fresh. Requests and bodies are not logged.
Dio createApiDio(AuthGateway gateway, {required String baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await gateway.accessToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ),
  );
  return dio;
}

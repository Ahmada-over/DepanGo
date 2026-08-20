import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config.dart';
import '../providers/app_providers.dart';
import '../providers/connectivity_provider.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Block requests if we know the server is offline (optional, to avoid spam)
        // But we allow them to fail fast.
        final token = ref.read(authProvider)?.token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        ref.read(serverConnectivityProvider.notifier).setOnline();
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          ref.read(serverConnectivityProvider.notifier).setOffline();
        } else {
          ref.read(serverConnectivityProvider.notifier).setOnline();
        }

        if (e.response?.statusCode == 401) {
          // Token expired or invalid
          ref.read(authProvider.notifier).logout();
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});

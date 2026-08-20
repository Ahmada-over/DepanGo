import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import '../providers/connectivity_provider.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('tech_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        ref.read(serverConnectivityProvider.notifier).setOnline();
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
          ref.read(serverConnectivityProvider.notifier).setOffline();
        } else {
          ref.read(serverConnectivityProvider.notifier).setOnline();
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});

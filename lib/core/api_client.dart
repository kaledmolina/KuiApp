
import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'https://kui.molinau.com';

  final Dio _dio;

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  Dio get dio => _dio;
}

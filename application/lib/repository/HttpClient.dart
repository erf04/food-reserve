import 'package:dio/dio.dart';

class HttpClient {
  static Dio instance = Dio(BaseOptions(baseUrl: "https://reserve-backend.chbk.run/"));
}

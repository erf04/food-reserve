import 'package:dio/dio.dart';

class HttpClient {
  static Dio instance = Dio(BaseOptions(baseUrl: "https://reserve.chbk.run/"));
}

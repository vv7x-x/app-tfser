import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config.dart';

class ApiService {
  static Future<Map<String, dynamic>> uploadReport({
    required String filePath,
    required double latitude,
    required double longitude,
    required String mediaType, // 'image' or 'video'
    String? reportedAtIso,
  }) async {
    final uri = Uri.parse('${AppConfig.serverBaseUrl}/report');

    final request = http.MultipartRequest('POST', uri)
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString();

    if (reportedAtIso != null) {
      request.fields['reported_at'] = reportedAtIso;
    }

    final contentType = mediaType == 'image' ? MediaType('image', 'jpeg') : MediaType('video', 'mp4');
    final filePart = await http.MultipartFile.fromPath('file', filePath, contentType: contentType);
    request.files.add(filePart);

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
}
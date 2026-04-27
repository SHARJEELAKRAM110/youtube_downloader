import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_downloader/models/video_info.dart';

class ApiService {
  // Change this to your deployed backend URL
  static const String baseUrl = 'http://localhost:3000';

  static Future<VideoInfo> fetchVideoInfo(String videoUrl) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/video/info?url=${Uri.encodeComponent(videoUrl)}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return VideoInfo.fromJson(data);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to fetch video info');
    }
  }

  static String getDownloadUrl(String videoUrl, String itag) {
    return '$baseUrl/api/video/download?url=${Uri.encodeComponent(videoUrl)}&itag=$itag';
  }
}

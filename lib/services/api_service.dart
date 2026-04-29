import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_downloader/models/video_info.dart';

class ApiService {
  // Gets backend URL depending on the environment
  static String get baseUrl {
    // Pass this via: flutter build web --dart-define=BACKEND_URL=https://your-api.com
    const definedUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
    if (definedUrl.isNotEmpty) return definedUrl;

    if (kReleaseMode) {
      // Fallback for production if BACKEND_URL is not provided via dart-define.
      return "https://youtubedownloader-production-42d8.up.railway.app";
      //'https://youtube-downloader-x6iq.onrender.com';
    }
    // Change line 18 in api_service.dart to this:
    return 'https://youtubedownloader-production-42d8.up.railway.app';
    // return 'http://localhost:3000';
  }

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
    return '$baseUrl/api/video/download?url=${Uri.encodeComponent(videoUrl)}&itag=${Uri.encodeComponent(itag)}';
  }
}
